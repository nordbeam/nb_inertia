defmodule NbInertia.Page.ChannelTest do
  use ExUnit.Case, async: true

  alias NbInertia.Extractor
  alias NbInertia.Extractor.Preamble

  # ══════════════════════════════════════════════════════════
  # Test Page Modules — Channel Support
  # ══════════════════════════════════════════════════════════

  defmodule BasicChannelPage do
    use NbInertia.Page, component: "Test/BasicChannel"

    prop(:room, :map)
    prop(:messages, :list)

    channel "chat:{room.id}" do
      on("message_created", prop: :messages, strategy: :append)
    end

    def mount(_conn, _params) do
      %{room: %{id: 1}, messages: []}
    end
  end

  defmodule MultiEventChannelPage do
    use NbInertia.Page, component: "Test/MultiEvent"

    prop(:room, :map)
    prop(:messages, :list)
    prop(:active_users, :list)
    prop(:typing_user, :map, nullable: true)

    channel "chat:{room.id}" do
      on("message_created", prop: :messages, strategy: :append)
      on("message_deleted", prop: :messages, strategy: :remove, key: :id)
      on("user_joined", prop: :active_users, strategy: :upsert, key: :id)
      on("user_left", prop: :active_users, strategy: :remove, key: :id)
      on("typing", prop: :typing_user, strategy: :replace)
    end

    def mount(_conn, _params) do
      %{room: %{id: 1}, messages: [], active_users: [], typing_user: nil}
    end
  end

  defmodule AllStrategiesPage do
    use NbInertia.Page, component: "Test/AllStrategies"

    prop(:list_prop, :list)
    prop(:single_prop, :map, nullable: true)

    channel "test:all" do
      on("ev_append", prop: :list_prop, strategy: :append)
      on("ev_prepend", prop: :list_prop, strategy: :prepend)
      on("ev_remove", prop: :list_prop, strategy: :remove, key: :id)
      on("ev_update", prop: :list_prop, strategy: :update, key: :id)
      on("ev_upsert", prop: :list_prop, strategy: :upsert, key: :id)
      on("ev_replace", prop: :single_prop, strategy: :replace)
      on("ev_reload", prop: :single_prop, strategy: :reload)
    end

    def mount(_conn, _params) do
      %{list_prop: [], single_prop: nil}
    end
  end

  defmodule KeyOptionPage do
    use NbInertia.Page, component: "Test/KeyOption"

    prop(:items, :list)

    channel "items:all" do
      on("item_removed", prop: :items, strategy: :remove, key: :id)
      on("item_updated", prop: :items, strategy: :update, key: :uuid)
    end

    def mount(_conn, _params) do
      %{items: []}
    end
  end

  defmodule NoChannelPage do
    use NbInertia.Page, component: "Test/NoChannel"

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end
  end

  defmodule ChannelWithRenderPage do
    use NbInertia.Page, component: "Test/ChannelWithRender"

    prop(:room, :map)
    prop(:messages, :list)

    channel "chat:{room.id}" do
      on("message_created", prop: :messages, strategy: :append)
      on("message_deleted", prop: :messages, strategy: :remove, key: :id)
    end

    def mount(_conn, _params) do
      %{room: %{id: 1}, messages: []}
    end

    def render do
      ~TSX"""
      export default function ChannelWithRender({ room, messages }: Props) {
        return <div>{messages.length} messages in room {room.id}</div>
      }
      """
    end
  end

  defmodule CamelizeChannelPage do
    use NbInertia.Page,
      component: "Test/CamelizeChannel",
      camelize_props: true

    prop(:active_users, :list)
    prop(:typing_user, :map, nullable: true)

    channel "room:{active_users}" do
      on("user_joined", prop: :active_users, strategy: :upsert, key: :id)
      on("typing_started", prop: :typing_user, strategy: :replace)
    end

    def mount(_conn, _params) do
      %{active_users: [], typing_user: nil}
    end
  end

  defmodule StandaloneChannelPage do
    use NbInertia.Page, component: "Chat/Show"

    prop(:room, :map)
    prop(:messages, :list)

    channel "chat:{room.id}" do
      on("message_created", prop: :messages, strategy: :append)
    end

    def mount(_conn, _params) do
      %{room: %{id: 1}, messages: []}
    end

    # No render/0 — standalone file pattern
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Channel Macro
  # ══════════════════════════════════════════════════════════

  describe "channel macro" do
    test "stores topic and events" do
      config = BasicChannelPage.__inertia_channel__()
      assert config != nil
      assert config.topic == "chat:{room.id}"
      assert length(config.events) == 1
    end

    test "on macro accumulates events with all options" do
      config = MultiEventChannelPage.__inertia_channel__()
      assert config.topic == "chat:{room.id}"
      assert length(config.events) == 5

      first_event = Enum.at(config.events, 0)
      assert first_event.event == "message_created"
      assert first_event.prop == :messages
      assert first_event.strategy == :append
      assert first_event.key == nil

      second_event = Enum.at(config.events, 1)
      assert second_event.event == "message_deleted"
      assert second_event.prop == :messages
      assert second_event.strategy == :remove
      assert second_event.key == :id
    end

    test "multiple events in one channel" do
      config = MultiEventChannelPage.__inertia_channel__()
      events = config.events
      event_names = Enum.map(events, & &1.event)

      assert "message_created" in event_names
      assert "message_deleted" in event_names
      assert "user_joined" in event_names
      assert "user_left" in event_names
      assert "typing" in event_names
    end

    test "all strategies compile" do
      config = AllStrategiesPage.__inertia_channel__()
      strategies = Enum.map(config.events, & &1.strategy)

      assert :append in strategies
      assert :prepend in strategies
      assert :remove in strategies
      assert :update in strategies
      assert :upsert in strategies
      assert :replace in strategies
      assert :reload in strategies
    end

    test "key option stored correctly" do
      config = KeyOptionPage.__inertia_channel__()

      removed_event = Enum.find(config.events, &(&1.event == "item_removed"))
      assert removed_event.key == :id

      updated_event = Enum.find(config.events, &(&1.event == "item_updated"))
      assert updated_event.key == :uuid
    end

    test "key is nil when not provided" do
      config = BasicChannelPage.__inertia_channel__()
      first_event = hd(config.events)
      assert first_event.key == nil
    end
  end

  describe "__inertia_channel__/0" do
    test "returns correct config" do
      config = BasicChannelPage.__inertia_channel__()
      assert is_map(config)
      assert Map.has_key?(config, :topic)
      assert Map.has_key?(config, :events)
    end

    test "returns nil when no channel declared" do
      assert NoChannelPage.__inertia_channel__() == nil
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Compile-Time Validation
  # ══════════════════════════════════════════════════════════

  describe "compile-time validation" do
    test "compile error when prop references non-existent prop" do
      assert_raise CompileError, ~r/references prop :nonexistent/, fn ->
        defmodule InvalidPropChannel do
          use NbInertia.Page, component: "Test/Invalid"

          prop(:data, :string)

          channel "test:1" do
            on("event", prop: :nonexistent, strategy: :replace)
          end

          def mount(_conn, _params), do: %{data: "hello"}
        end
      end
    end

    test "valid prop references compile fine" do
      # BasicChannelPage already compiled successfully with valid prop reference
      config = BasicChannelPage.__inertia_channel__()
      assert config != nil
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Preamble Generation (Channel Config)
  # ══════════════════════════════════════════════════════════

  describe "preamble channel config generation" do
    test "channel config generates import statements" do
      channel_config = %{
        topic: "chat:{room.id}",
        events: [
          %{
            event: "message_created",
            prop: :messages,
            strategy: :append,
            key: nil,
            transform: nil
          }
        ]
      }

      props = [%{name: :room, type: :map, opts: []}, %{name: :messages, type: :list, opts: []}]

      result = Preamble.generate(props, channel: channel_config)

      assert result =~
               "import { useChannelProps } from '@nordbeam/nb-inertia/react/realtime/useChannelProps'"

      assert result =~ "import { socket } from '@/lib/socket'"
    end

    test "channel config generates __channelConfig constant" do
      channel_config = %{
        topic: "chat:{room.id}",
        events: [
          %{
            event: "message_created",
            prop: :messages,
            strategy: :append,
            key: nil,
            transform: nil
          }
        ]
      }

      props = [%{name: :messages, type: :list, opts: []}]

      result = Preamble.generate(props, channel: channel_config)

      assert result =~ "const __channelConfig = ["
      assert result =~ "event: 'message_created'"
      assert result =~ "prop: 'messages'"
      assert result =~ "strategy: 'append'"
      assert result =~ "] as const"
    end

    test "event prop names are camelized when applicable" do
      channel_config = %{
        topic: "room:1",
        events: [
          %{
            event: "user_joined",
            prop: :active_users,
            strategy: :upsert,
            key: :id,
            transform: nil
          },
          %{
            event: "typing_started",
            prop: :typing_user,
            strategy: :replace,
            key: nil,
            transform: nil
          }
        ]
      }

      props = [
        %{name: :active_users, type: :list, opts: []},
        %{name: :typing_user, type: :map, opts: []}
      ]

      result = Preamble.generate(props, channel: channel_config, camelize_props: true)

      assert result =~ "prop: 'activeUsers'"
      assert result =~ "prop: 'typingUser'"
    end

    test "key option included in config" do
      channel_config = %{
        topic: "test:1",
        events: [
          %{event: "item_removed", prop: :items, strategy: :remove, key: :id, transform: nil}
        ]
      }

      props = [%{name: :items, type: :list, opts: []}]

      result = Preamble.generate(props, channel: channel_config)

      assert result =~ "key: 'id'"
    end

    test "key option omitted when nil" do
      channel_config = %{
        topic: "test:1",
        events: [
          %{event: "updated", prop: :data, strategy: :replace, key: nil, transform: nil}
        ]
      }

      props = [%{name: :data, type: :map, opts: []}]

      result = Preamble.generate(props, channel: channel_config)

      refute result =~ "key:"
    end

    test "no channel section when channel is nil" do
      props = [%{name: :data, type: :string, opts: []}]

      result = Preamble.generate(props, channel: nil)

      refute result =~ "useChannelProps"
      refute result =~ "__channelConfig"
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Preamble Channel Config File Generation
  # ══════════════════════════════════════════════════════════

  describe "Preamble.generate_channel_config/2" do
    test "generates standalone channel config file" do
      channel_config = %{
        topic: "chat:{room.id}",
        events: [
          %{
            event: "message_created",
            prop: :messages,
            strategy: :append,
            key: nil,
            transform: nil
          }
        ]
      }

      result = Preamble.generate_channel_config(channel_config, module: MyAppWeb.ChatPage.Show)

      assert result =~ "// AUTO-GENERATED channel config for MyAppWeb.ChatPage.Show"
      assert result =~ "export const channelConfig = ["
      assert result =~ "event: 'message_created'"
      assert result =~ "export const channelTopic = 'chat:{room.id}'"
    end

    test "camelizes props when requested" do
      channel_config = %{
        topic: "room:1",
        events: [
          %{
            event: "user_joined",
            prop: :active_users,
            strategy: :upsert,
            key: :id,
            transform: nil
          }
        ]
      }

      result = Preamble.generate_channel_config(channel_config, camelize_props: true)

      assert result =~ "prop: 'activeUsers'"
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Extraction (Channel + Render)
  # ══════════════════════════════════════════════════════════

  describe "extraction with channel and render/0" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "nb_inertia_channel_test_#{:rand.uniform(100_000)}")
      File.rm_rf!(tmp_dir)
      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      %{output_dir: tmp_dir}
    end

    test "module with channel + render/0: channel config in preamble", %{output_dir: output_dir} do
      result = Extractor.extract_module(ChannelWithRenderPage, output_dir: output_dir)

      assert {:ok, path} = result

      content = File.read!(path)

      # Should have channel imports
      assert content =~ "useChannelProps"
      assert content =~ "socket"

      # Should have channel config
      assert content =~ "__channelConfig"
      assert content =~ "message_created"
      assert content =~ "strategy: 'append'"

      # Should have Props interface
      assert content =~ "interface Props {"
      assert content =~ "room: Record<string, any>"
      assert content =~ "messages: any[]"

      # Should have render content
      assert content =~ "export default function ChannelWithRender"
    end

    test "module with channel + camelize_props: props camelized in config",
         %{output_dir: output_dir} do
      result = Extractor.extract_module(CamelizeChannelPage, output_dir: output_dir)

      # CamelizeChannelPage has no render/0, so it won't be extracted by extract_module
      # (which requires render). Let's test via the preamble directly instead.
      assert {:error, _, _} = result
    end

    test "camelized channel config in preamble" do
      channel_config = CamelizeChannelPage.__inertia_channel__()
      props = CamelizeChannelPage.__inertia_props__()

      result = Preamble.generate(props, channel: channel_config, camelize_props: true)

      assert result =~ "prop: 'activeUsers'"
      assert result =~ "prop: 'typingUser'"
    end
  end

  describe "extraction: companion config for standalone pages" do
    setup do
      tmp_dir =
        Path.join(System.tmp_dir!(), "nb_inertia_channel_standalone_#{:rand.uniform(100_000)}")

      File.rm_rf!(tmp_dir)

      # Also clean the companion channels directory
      channels_dir = Path.join(Path.dirname(tmp_dir), "channels")
      File.rm_rf!(channels_dir)

      on_exit(fn ->
        File.rm_rf!(tmp_dir)
        File.rm_rf!(channels_dir)
      end)

      %{output_dir: tmp_dir}
    end

    test "module with channel + no render/0: companion config file generated",
         %{output_dir: output_dir} do
      result =
        Extractor.extract_channel_config(StandaloneChannelPage,
          output_dir: output_dir,
          incremental: false
        )

      assert {:ok, path} = result
      assert String.ends_with?(path, "Chat/Show.config.ts")

      content = File.read!(path)

      assert content =~ "AUTO-GENERATED channel config"
      assert content =~ "export const channelConfig = ["
      assert content =~ "message_created"
      assert content =~ "export const channelTopic = 'chat:{room.id}'"
    end

    test "extract_all generates companion configs for standalone channel pages",
         %{output_dir: output_dir} do
      results =
        Extractor.extract_all(
          output_dir: output_dir,
          modules: [StandaloneChannelPage, ChannelWithRenderPage, NoChannelPage],
          incremental: false
        )

      # ChannelWithRenderPage has render/0 — extracted as page
      # StandaloneChannelPage has no render/0 but has channel — companion config
      # NoChannelPage has no render/0 and no channel — nothing

      ok_results = Enum.filter(results, &match?({:ok, _}, &1))
      # One for ChannelWithRenderPage tsx, one for StandaloneChannelPage config
      assert length(ok_results) == 2

      paths = Enum.map(ok_results, fn {:ok, path} -> path end)

      assert Enum.any?(paths, &String.ends_with?(&1, "Test/ChannelWithRender.tsx"))
      assert Enum.any?(paths, &String.ends_with?(&1, "Chat/Show.config.ts"))
    end
  end
end
