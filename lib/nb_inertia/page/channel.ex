defmodule NbInertia.Page.Channel do
  @moduledoc """
  Declarative channel bindings for Page modules.

  Provides the `channel/2` and `on/2` macros that allow Page modules to
  declare real-time channel subscriptions and event handlers at compile time.
  The configuration is stored as module attributes and exposed via the
  `__inertia_channel__/0` introspection function.

  ## Usage

      defmodule MyAppWeb.ChatPage.Show do
        use NbInertia.Page

        prop :room, RoomSerializer
        prop :messages, list: MessageSerializer
        prop :active_users, list: UserSerializer
        prop :typing_user, :map, nullable: true

        channel "chat:{room.id}" do
          on "message_created", prop: :messages, strategy: :append
          on "message_deleted", prop: :messages, strategy: :remove, key: :id
          on "user_joined",     prop: :active_users, strategy: :upsert, key: :id
          on "typing",          prop: :typing_user, strategy: :replace
        end

        def mount(_conn, %{"id" => id}) do
          room = Chat.get_room!(id)
          %{room: room, messages: Chat.recent_messages(room), active_users: Chat.active_users(room)}
        end
      end

  ## Topic Interpolation

  The topic string supports interpolation syntax like `"chat:{room.id}"`.
  The `{room.id}` portion is resolved on the frontend from the `:room` prop's
  `id` field. The Elixir side stores the string as-is — interpolation is
  handled by the frontend runtime.

  ## Strategies

  | Strategy   | Description                        |
  |------------|------------------------------------|
  | `:append`  | Add to end of list                 |
  | `:prepend` | Add to beginning of list           |
  | `:remove`  | Remove by key match                |
  | `:update`  | Update existing item by key match  |
  | `:upsert`  | Update if exists, append if not    |
  | `:replace` | Replace entire prop value          |
  | `:reload`  | Trigger full Inertia reload        |
  """

  @valid_strategies [:append, :prepend, :remove, :update, :upsert, :replace, :reload]

  @doc """
  Declares a channel subscription for this page.

  The `topic` is a string that may contain interpolation placeholders
  (e.g., `"chat:{room.id}"`). The block should contain `on/2` declarations
  for each event the page listens to.

  ## Examples

      channel "chat:{room.id}" do
        on "message_created", prop: :messages, strategy: :append
        on "typing",          prop: :typing_user, strategy: :replace
      end
  """
  defmacro channel(topic, do: block) do
    quote do
      @nb_page_channel_topic unquote(topic)

      # Clear any previously accumulated events by deleting and re-registering
      Module.delete_attribute(__MODULE__, :nb_page_channel_events)
      Module.register_attribute(__MODULE__, :nb_page_channel_events, accumulate: true)

      unquote(block)

      @nb_page_channel %{
        topic: @nb_page_channel_topic,
        events: Enum.reverse(@nb_page_channel_events)
      }
    end
  end

  @doc """
  Declares an event handler within a `channel/2` block.

  ## Options

    * `:prop` - (required) The prop name this event updates
    * `:strategy` - (required) The update strategy (`:append`, `:prepend`,
      `:remove`, `:update`, `:upsert`, `:replace`, `:reload`)
    * `:key` - (optional) The key field for `:remove`, `:update`, and `:upsert` strategies
    * `:transform` - (optional) A transform function applied to the event payload

  ## Examples

      on "message_created", prop: :messages, strategy: :append
      on "message_deleted", prop: :messages, strategy: :remove, key: :id
      on "user_joined",     prop: :active_users, strategy: :upsert, key: :id
      on "typing",          prop: :typing_user, strategy: :replace
  """
  defmacro on(event, opts) do
    # Validate required options at compile time
    unless Keyword.has_key?(opts, :prop) do
      raise CompileError,
        description: "on/2 requires the :prop option",
        file: __CALLER__.file,
        line: __CALLER__.line
    end

    unless Keyword.has_key?(opts, :strategy) do
      raise CompileError,
        description: "on/2 requires the :strategy option",
        file: __CALLER__.file,
        line: __CALLER__.line
    end

    strategy = Keyword.fetch!(opts, :strategy)

    unless strategy in @valid_strategies do
      raise CompileError,
        description:
          "on/2 :strategy must be one of #{inspect(@valid_strategies)}, got: #{inspect(strategy)}",
        file: __CALLER__.file,
        line: __CALLER__.line
    end

    quote do
      @nb_page_channel_events %{
        event: unquote(event),
        prop: unquote(Keyword.fetch!(opts, :prop)),
        strategy: unquote(Keyword.fetch!(opts, :strategy)),
        key: unquote(Keyword.get(opts, :key)),
        transform: unquote(Keyword.get(opts, :transform))
      }
    end
  end

  @doc false
  @spec valid_strategies() :: list(atom())
  def valid_strategies, do: @valid_strategies
end
