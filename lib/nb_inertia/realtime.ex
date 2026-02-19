defmodule NbInertia.Realtime do
  @moduledoc """
  Phoenix Channel integration for real-time Inertia.js prop updates.

  This module provides helpers for broadcasting prop updates through Phoenix Channels
  with automatic serialization that matches `render_inertia/3` behavior.

  ## Overview

  NbInertia.Realtime enables WebSocket-based real-time updates for Inertia.js pages,
  eliminating the need for polling. It integrates seamlessly with Phoenix Channels
  and provides consistent serialization with HTTP responses.

  ## Usage Patterns

  ### Pattern 1: Standard Phoenix Broadcast (Recommended for simplicity)

  You can use standard Phoenix broadcasting without any special helpers:

      defmodule MyApp.Chat do
        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(Message.changeset(attrs))

          # Standard Phoenix broadcast
          MyAppWeb.Endpoint.broadcast("chat:\#{room.id}", "message_created", %{
            message: MyApp.Serializers.MessageSerializer.serialize(message)
          })

          {:ok, message}
        end
      end

  ### Pattern 2: Using NbInertia.Realtime Helpers

  For consistent serialization with `render_inertia/3`, use the broadcast helper:

      defmodule MyApp.Chat do
        import NbInertia.Realtime

        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(Message.changeset(attrs))

          # Broadcast with tuple serialization (same as render_inertia)
          broadcast(MyAppWeb.Endpoint, "chat:\#{room.id}", "message_created",
            message: {MyApp.Serializers.MessageSerializer, message}
          )

          {:ok, message}
        end
      end

  ### Pattern 3: Using the `use` macro

  For a cleaner API, use the module macro:

      defmodule MyApp.Chat do
        use NbInertia.Realtime, endpoint: MyAppWeb.Endpoint

        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(Message.changeset(attrs))

          # Endpoint is pre-configured
          broadcast("chat:\#{room.id}", "message_created",
            message: {MyApp.Serializers.MessageSerializer, message}
          )

          {:ok, message}
        end
      end

  ## Serialization

  The `broadcast/4` function supports the same tuple serialization as `render_inertia/3`:

  - `{SerializerModule, data}` - Calls `SerializerModule.serialize(data)`
  - `{SerializerModule, data, opts}` - Calls `SerializerModule.serialize(data, opts)`
  - Plain values - Passed through unchanged

  This ensures consistency between HTTP responses and WebSocket messages.

  ## Frontend Integration

  On the frontend, use the companion hooks to receive updates:

      import { useChannel } from '@/lib/socket';
      import { useRealtimeProps } from '@/lib/inertia';

      export default function ChatRoom({ room }) {
        const { props, setProp } = useRealtimeProps<ChatRoomProps>();

        useChannel(`chat:\${room.id}`, {
          message_created: ({ message }) => {
            setProp('messages', msgs => [...msgs, message]);
          }
        });

        return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
      }

  ## Installation

  Run the generator to set up WebSocket support:

      mix nb_inertia.gen.realtime

  This creates:
  - `lib/my_app_web/channels/user_socket.ex` (if not exists)
  - `assets/js/lib/socket.ts` with `useChannel` and `usePresence` hooks
  - `assets/js/lib/realtime.ts` with `useRealtimeProps` and `useChannelProps` hooks
  """

  @doc """
  Broadcast a message through Phoenix Channels with automatic serialization.

  ## Arguments

  - `endpoint` - The Phoenix Endpoint module
  - `topic` - The channel topic (e.g., "chat:123")
  - `event` - The event name (e.g., "message_created")
  - `payload` - Keyword list or map of data to broadcast

  ## Serialization

  Values in the payload support tuple serialization:

  - `{SerializerModule, data}` - Calls `SerializerModule.serialize(data)`
  - `{SerializerModule, data, opts}` - Calls `SerializerModule.serialize(data, opts)`
  - Plain values - Passed through unchanged

  ## Examples

      # With serializer tuple
      broadcast(MyAppWeb.Endpoint, "chat:1", "message_created",
        message: {MessageSerializer, message}
      )

      # With plain values
      broadcast(MyAppWeb.Endpoint, "chat:1", "typing",
        user_id: user.id,
        is_typing: true
      )

      # Mixed
      broadcast(MyAppWeb.Endpoint, "chat:1", "message_updated",
        message: {MessageSerializer, message},
        edited_at: DateTime.utc_now()
      )
  """
  @spec broadcast(module(), String.t(), String.t(), keyword() | map()) :: :ok | {:error, term()}
  def broadcast(endpoint, topic, event, payload) when is_list(payload) do
    broadcast(endpoint, topic, event, Map.new(payload))
  end

  def broadcast(endpoint, topic, event, payload) when is_map(payload) do
    serialized = serialize_payload(payload)
    endpoint.broadcast(topic, event, serialized)
  end

  @doc """
  Broadcast a message from a specific socket process.

  Similar to `broadcast/4` but uses `broadcast_from/4` to exclude the sender.

  ## Examples

      broadcast_from(socket, "chat:1", "message_created",
        message: {MessageSerializer, message}
      )
  """
  @spec broadcast_from(Phoenix.Socket.t(), String.t(), String.t(), keyword() | map()) ::
          :ok | {:error, term()}
  def broadcast_from(socket, topic, event, payload) when is_list(payload) do
    broadcast_from(socket, topic, event, Map.new(payload))
  end

  def broadcast_from(socket, topic, event, payload) when is_map(payload) do
    serialized = serialize_payload(payload)
    socket.endpoint.broadcast_from(self(), topic, event, serialized)
  end

  @doc """
  Serialize a payload for broadcasting.

  Handles tuple serialization for values:
  - `{SerializerModule, data}` - Calls `SerializerModule.serialize(data, [])`
  - `{SerializerModule, data, opts}` - Calls `SerializerModule.serialize(data, opts)`
  - Plain values - Passed through unchanged

  ## Examples

      serialize_payload(%{
        message: {MessageSerializer, message},
        timestamp: DateTime.utc_now()
      })
      # => %{message: %{id: 1, content: "..."}, timestamp: ~U[2024-01-01 00:00:00Z]}
  """
  @spec serialize_payload(map()) :: map()
  def serialize_payload(payload) when is_map(payload) do
    Map.new(payload, fn {key, value} ->
      {key, serialize_value(value)}
    end)
  end

  defp serialize_value({serializer, data}) when is_atom(serializer) do
    try do
      serializer.serialize(data, [])
    rescue
      e ->
        reraise "NbInertia.Realtime: serializer #{inspect(serializer)} failed on #{inspect(data)}: #{Exception.message(e)}",
                __STACKTRACE__
    end
  end

  defp serialize_value({serializer, data, opts}) when is_atom(serializer) and is_list(opts) do
    try do
      serializer.serialize(data, opts)
    rescue
      e ->
        reraise "NbInertia.Realtime: serializer #{inspect(serializer)} failed on #{inspect(data)} with opts #{inspect(opts)}: #{Exception.message(e)}",
                __STACKTRACE__
    end
  end

  defp serialize_value(value), do: value

  @doc """
  Defines helpers for real-time broadcasting in a context module.

  ## Usage

      defmodule MyApp.Chat do
        use NbInertia.Realtime, endpoint: MyAppWeb.Endpoint

        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(...)

          # No need to pass endpoint
          broadcast("chat:\#{room.id}", "message_created",
            message: {MessageSerializer, message}
          )

          {:ok, message}
        end
      end

  ## Options

  - `:endpoint` - (required) The Phoenix Endpoint module to use for broadcasting
  """
  defmacro __using__(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    quote do
      import NbInertia.Realtime, only: [serialize_payload: 1]

      @doc """
      Broadcast a message through Phoenix Channels.

      See `NbInertia.Realtime.broadcast/4` for details.
      """
      def broadcast(topic, event, payload) do
        NbInertia.Realtime.broadcast(unquote(endpoint), topic, event, payload)
      end

      @doc """
      Broadcast a message excluding the sender.

      See `NbInertia.Realtime.broadcast_from/4` for details.
      """
      def broadcast_from(socket, topic, event, payload) do
        NbInertia.Realtime.broadcast_from(socket, topic, event, payload)
      end
    end
  end
end
