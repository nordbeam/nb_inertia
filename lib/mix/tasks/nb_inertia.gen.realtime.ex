defmodule Mix.Tasks.NbInertia.Gen.Realtime.Docs do
  @moduledoc false

  def short_doc do
    "Generates real-time WebSocket support for NbInertia with Phoenix Channels."
  end

  def example do
    "mix nb_inertia.gen.realtime"
  end

  def long_doc do
    """
    Generates real-time WebSocket support for NbInertia with Phoenix Channels.

    This generator sets up everything needed for real-time prop updates via
    Phoenix Channels, eliminating the need for polling.

    ## What Gets Generated

    1. **Backend:**
       - `lib/my_app_web/channels/user_socket.ex` - Phoenix Socket module
       - Socket route in `lib/my_app_web/endpoint.ex`

    2. **Frontend:**
       - `assets/js/lib/socket.{ts,js}` - Socket setup with hooks
       - Installs `phoenix` npm package for JavaScript client

    ## Usage

    ```bash
    mix nb_inertia.gen.realtime
    ```

    ## Options

        --typescript    Generate TypeScript files (default if tsconfig.json exists)
        --yes           Don't prompt for confirmations

    ## After Generation

    ### 1. Create a Channel

    Create a channel for your feature:

    ```elixir
    # lib/my_app_web/channels/chat_channel.ex
    defmodule MyAppWeb.ChatChannel do
      use Phoenix.Channel

      def join("chat:" <> room_id, _params, socket) do
        {:ok, assign(socket, :room_id, room_id)}
      end
    end
    ```

    Add it to your socket:

    ```elixir
    # lib/my_app_web/channels/user_socket.ex
    channel "chat:*", MyAppWeb.ChatChannel
    ```

    ### 2. Broadcast Updates

    From your context modules:

    ```elixir
    defmodule MyApp.Chat do
      def create_message(room, attrs) do
        {:ok, message} = Repo.insert(Message.changeset(attrs))

        MyAppWeb.Endpoint.broadcast("chat:\#{room.id}", "message_created", %{
          message: MyApp.Serializers.MessageSerializer.serialize(message)
        })

        {:ok, message}
      end
    end
    ```

    ### 3. Subscribe in React

    ```typescript
    import { socket, useChannel, useRealtimeProps } from '@/lib/socket';

    function ChatRoom({ room }) {
      const { props, setProp } = useRealtimeProps<ChatRoomProps>();

      useChannel(socket, `chat:\${room.id}`, {
        message_created: ({ message }) => {
          setProp('messages', msgs => [...msgs, message]);
        }
      });

      return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
    }
    ```

    ## Declarative Mode

    For complex apps, use the declarative `useChannelProps` hook:

    ```typescript
    import { socket, useChannelProps } from '@/lib/socket';

    function ChatRoom({ room }) {
      const { props } = useChannelProps<ChatRoomProps, ChatEvents>(
        socket,
        `chat:\${room.id}`,
        {
          message_created: {
            prop: 'messages',
            strategy: 'append',
            transform: e => e.message
          },
          message_deleted: {
            prop: 'messages',
            strategy: 'remove',
            match: (m, e) => m.id === e.id
          }
        }
      );

      return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
    }
    ```

    ## Available Strategies

    - `append` - Add item to end of array
    - `prepend` - Add item to start of array
    - `remove` - Remove items matching predicate
    - `update` - Update item in place by key
    - `upsert` - Update if exists, append if not
    - `replace` - Replace entire prop value
    - `reload` - Reload prop(s) from server

    For more information:
    - NbInertia Realtime docs: https://hexdocs.pm/nb_inertia/realtime.html
    - Phoenix Channels: https://hexdocs.pm/phoenix/channels.html
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NbInertia.Gen.Realtime do
    @shortdoc Mix.Tasks.NbInertia.Gen.Realtime.Docs.short_doc()

    @moduledoc Mix.Tasks.NbInertia.Gen.Realtime.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :nb,
        schema: [
          typescript: :boolean,
          yes: :boolean
        ],
        example: Mix.Tasks.NbInertia.Gen.Realtime.Docs.example(),
        defaults: [],
        positional: [],
        composes: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> create_user_socket()
      |> add_socket_to_endpoint()
      |> install_phoenix_js()
      |> create_socket_js()
      |> print_next_steps()
    end

    # ========================================================================
    # Helpers
    # ========================================================================

    defp web_module(igniter) do
      Igniter.Libs.Phoenix.web_module(igniter)
    end

    defp web_dir(igniter) do
      igniter
      |> web_module()
      |> inspect()
      |> Macro.underscore()
    end

    defp using_typescript?(igniter) do
      # Check if explicitly set, or detect from tsconfig.json
      case igniter.args.options[:typescript] do
        true -> true
        false -> false
        nil -> Igniter.exists?(igniter, "assets/tsconfig.json")
      end
    end

    defp get_package_manager(_igniter) do
      cond do
        File.exists?("assets/bun.lockb") -> "bun"
        File.exists?("assets/pnpm-lock.yaml") -> "pnpm"
        File.exists?("assets/yarn.lock") -> "yarn"
        File.exists?("assets/package-lock.json") -> "npm"
        System.find_executable("bun") -> "bun"
        System.find_executable("pnpm") -> "pnpm"
        System.find_executable("yarn") -> "yarn"
        true -> "npm"
      end
    end

    # ========================================================================
    # User Socket
    # ========================================================================

    defp create_user_socket(igniter) do
      web_mod = web_module(igniter)
      web_dir_name = web_dir(igniter)
      socket_path = Path.join(["lib", web_dir_name, "channels", "user_socket.ex"])

      if Igniter.exists?(igniter, socket_path) do
        # Socket already exists, skip
        igniter
      else
        # Create user socket from template
        content = user_socket_template(web_mod)
        Igniter.create_new_file(igniter, socket_path, content)
      end
    end

    defp user_socket_template(web_module) do
      """
      defmodule #{inspect(web_module)}.UserSocket do
        use Phoenix.Socket

        # Add your channels here. Example:
        #
        #     channel "room:*", #{inspect(web_module)}.RoomChannel
        #
        # To add real-time features:
        # 1. Create a channel module (e.g., lib/#{Macro.underscore(inspect(web_module))}/channels/room_channel.ex)
        # 2. Add the channel route above
        # 3. Subscribe from React using useChannel hook

        @impl true
        def connect(_params, socket, _connect_info) do
          # Verify authentication here if needed.
          # Example with user authentication:
          #
          #   case verify_token(params["token"]) do
          #     {:ok, user_id} -> {:ok, assign(socket, :user_id, user_id)}
          #     {:error, _} -> :error
          #   end

          {:ok, socket}
        end

        @impl true
        def id(_socket) do
          # Return nil for anonymous connections.
          # For authenticated users, return a unique identifier:
          #
          #   "user_socket:\#{socket.assigns.user_id}"
          nil
        end
      end
      """
    end

    # ========================================================================
    # Endpoint Socket Route
    # ========================================================================

    defp add_socket_to_endpoint(igniter) do
      {igniter, endpoint_module} = Igniter.Libs.Phoenix.select_endpoint(igniter)

      case Igniter.Project.Module.find_module(igniter, endpoint_module) do
        {:ok, {igniter, _source, _zipper}} ->
          # Check if socket is already configured
          Igniter.Project.Module.find_and_update_module!(igniter, endpoint_module, fn zipper ->
            # Look for existing socket configuration
            case Igniter.Code.Common.move_to(zipper, fn z ->
                   Igniter.Code.Function.function_call?(z, :socket)
                 end) do
              {:ok, _} ->
                # Socket already configured
                {:ok, zipper}

              :error ->
                # Add socket configuration after use Phoenix.Endpoint
                web_mod = web_module(igniter)

                socket_code = """
                  socket "/socket", #{inspect(web_mod)}.UserSocket,
                    websocket: true,
                    longpoll: false
                """

                with {:ok, zipper} <- move_to_after_use_endpoint(zipper) do
                  {:ok, Igniter.Code.Common.add_code(zipper, socket_code)}
                else
                  _ ->
                    {:warning,
                     "Could not find `use Phoenix.Endpoint` in #{inspect(endpoint_module)}. " <>
                       "You may need to manually add the socket configuration."}
                end
            end
          end)

        {:error, igniter} ->
          Igniter.add_warning(
            igniter,
            "Could not find endpoint module #{inspect(endpoint_module)}. " <>
              "You may need to manually add the socket configuration."
          )
      end
    end

    defp move_to_after_use_endpoint(zipper) do
      case Igniter.Code.Common.move_to(zipper, fn z ->
             Igniter.Code.Function.function_call?(z, :use) &&
               match?({:ok, _}, Igniter.Code.Function.argument_equals?(z, 0, Phoenix.Endpoint))
           end) do
        {:ok, zipper} -> {:ok, zipper}
        :error -> :error
      end
    end

    # ========================================================================
    # Install Phoenix JS
    # ========================================================================

    defp install_phoenix_js(igniter) do
      pkg_manager = get_package_manager(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" -> "bun add --cwd #{assets_dir} phoenix"
          "pnpm" -> "pnpm add --dir #{assets_dir} phoenix"
          "yarn" -> "yarn --cwd #{assets_dir} add phoenix"
          _ -> "npm install --prefix #{assets_dir} phoenix"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    # ========================================================================
    # Socket JS
    # ========================================================================

    defp create_socket_js(igniter) do
      typescript = using_typescript?(igniter)
      extension = if typescript, do: "ts", else: "js"
      socket_path = Path.join(["assets", "js", "lib", "socket.#{extension}"])

      if Igniter.exists?(igniter, socket_path) do
        # Socket file already exists, skip
        igniter
      else
        content = socket_js_template(typescript)
        Igniter.create_new_file(igniter, socket_path, content)
      end
    end

    defp socket_js_template(typescript) do
      type_imports =
        if typescript do
          """

          // Re-export types
          export type {
            EventHandler,
            EventHandlers,
            ChannelOptions,
            PresenceState,
            PresenceOptions,
            SocketOptions,
            ReloadOptions,
            UseRealtimePropsReturn,
            UpdateStrategy,
            DeclarativeEventConfig,
            CustomEventHandler,
            EventConfig,
            EventConfigs,
            UseChannelPropsReturn,
          } from '@nordbeam/nb-inertia/react/realtime';
          """
        else
          ""
        end

      meta_selector =
        if typescript do
          "document.querySelector<HTMLMetaElement>('meta[name=\"csrf-token\"]')"
        else
          "document.querySelector('meta[name=\"csrf-token\"]')"
        end

      """
      /**
       * Phoenix Socket Configuration
       *
       * This file sets up the Phoenix Socket connection and re-exports
       * channel hooks from @nordbeam/nb-inertia for real-time features.
       *
       * Usage:
       *   import { socket, useChannel, useRealtimeProps } from '@/lib/socket';
       *
       *   function ChatRoom({ room }) {
       *     const { props, setProp } = useRealtimeProps#{if typescript, do: "<ChatRoomProps>", else: ""}();
       *
       *     useChannel(socket, `chat:\${room.id}`, {
       *       message_created: ({ message }) => {
       *         setProp('messages', msgs => [...msgs, message]);
       *       }
       *     });
       *
       *     return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
       *   }
       */

      import {
        createSocket,
        useChannel,
        usePresence,
        useRealtimeProps,
        useChannelProps,
      } from '@nordbeam/nb-inertia/react/realtime';

      // Create and connect the socket
      export const socket = createSocket('/socket', {
        params: () => {
          const token = #{meta_selector};
          return { _csrf_token: token?.content };
        },
      });

      // Connect the socket
      socket.connect();

      // Re-export hooks for convenience
      export {
        useChannel,
        usePresence,
        useRealtimeProps,
        useChannelProps,
        createSocket,
      };
      #{type_imports}
      """
    end

    # ========================================================================
    # Next Steps
    # ========================================================================

    defp print_next_steps(igniter) do
      typescript = using_typescript?(igniter)
      extension = if typescript, do: "ts", else: "js"
      web_mod = web_module(igniter)
      web_dir_name = web_dir(igniter)

      next_steps = """
      Real-time WebSocket support has been generated!

      ## What was created

      1. **Backend:**
         - lib/#{web_dir_name}/channels/user_socket.ex
         - Socket route added to endpoint

      2. **Frontend:**
         - assets/js/lib/socket.#{extension}
         - Installed `phoenix` npm package

      ## Next Steps

      ### 1. Create a Channel

      ```elixir
      # lib/#{web_dir_name}/channels/chat_channel.ex
      defmodule #{inspect(web_mod)}.ChatChannel do
        use Phoenix.Channel

        def join("chat:" <> room_id, _params, socket) do
          {:ok, assign(socket, :room_id, room_id)}
        end
      end
      ```

      Add it to your socket:

      ```elixir
      # lib/#{web_dir_name}/channels/user_socket.ex
      channel "chat:*", #{inspect(web_mod)}.ChatChannel
      ```

      ### 2. Broadcast Updates

      ```elixir
      defmodule MyApp.Chat do
        def create_message(room, attrs) do
          {:ok, message} = Repo.insert(...)

          #{inspect(web_mod)}.Endpoint.broadcast(
            "chat:\#{room.id}",
            "message_created",
            %{message: MessageSerializer.serialize(message)}
          )

          {:ok, message}
        end
      end
      ```

      ### 3. Subscribe in React

      ```#{if typescript, do: "typescript", else: "javascript"}
      import { socket, useChannel, useRealtimeProps } from '@/lib/socket';

      function ChatRoom({ room }#{if typescript, do: ": ChatRoomProps", else: ""}) {
        const { props, setProp } = useRealtimeProps#{if typescript, do: "<ChatRoomProps>", else: ""}();

        useChannel(socket, `chat:\${room.id}`, {
          message_created: ({ message }) => {
            setProp('messages', msgs => [...msgs, message]);
          }
        });

        return (
          <div>
            {props.messages.map(m => <Message key={m.id} {...m} />)}
          </div>
        );
      }
      ```

      ## Documentation

      - NbInertia Realtime: https://hexdocs.pm/nb_inertia/realtime.html
      - Phoenix Channels: https://hexdocs.pm/phoenix/channels.html
      """

      Igniter.add_notice(igniter, next_steps)
    end
  end
else
  defmodule Mix.Tasks.NbInertia.Gen.Realtime do
    @shortdoc "Install `igniter` in order to use this generator."

    @moduledoc Mix.Tasks.NbInertia.Gen.Realtime.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'nb_inertia.gen.realtime' requires igniter. Please install igniter and try again.

      Add to your mix.exs:

          {:igniter, "~> 0.5", only: [:dev]}

      Then run:

          mix deps.get
          mix nb_inertia.gen.realtime

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
