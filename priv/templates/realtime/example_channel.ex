defmodule <%= web_module %>.RoomChannel do
  @moduledoc """
  Example Phoenix Channel for real-time features.

  ## Usage

  1. Add to your UserSocket:

      channel "room:*", <%= web_module %>.RoomChannel

  2. Subscribe from React:

      import { socket, useChannel, useRealtimeProps } from '@/lib/socket';

      function ChatRoom({ room }) {
        const { props, setProp } = useRealtimeProps<ChatRoomProps>();

        useChannel(socket, `room:\${room.id}`, {
          new_message: ({ message }) => {
            setProp('messages', msgs => [...msgs, message]);
          }
        });

        return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
      }

  3. Broadcast from your context:

      defmodule MyApp.Chat do
        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(Message.changeset(attrs))

          <%= web_module %>.Endpoint.broadcast("room:\#{room.id}", "new_message", %{
            message: MyApp.Serializers.MessageSerializer.serialize(message)
          })

          {:ok, message}
        end
      end
  """

  use Phoenix.Channel

  @impl true
  def join("room:" <> room_id, _params, socket) do
    # You can add authorization logic here
    # Example:
    #   if authorized?(socket.assigns.user_id, room_id) do
    #     {:ok, assign(socket, :room_id, room_id)}
    #   else
    #     {:error, %{reason: "unauthorized"}}
    #   end

    {:ok, assign(socket, :room_id, room_id)}
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    # Handle incoming messages from clients
    # Example: Save to database and broadcast to others

    broadcast_from!(socket, "new_message", %{
      content: content,
      user_id: socket.assigns[:user_id],
      inserted_at: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("typing", %{"typing" => is_typing}, socket) do
    # Broadcast typing indicator
    broadcast_from!(socket, "user_typing", %{
      user_id: socket.assigns[:user_id],
      typing: is_typing
    })

    {:noreply, socket}
  end
end
