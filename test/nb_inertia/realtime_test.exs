defmodule NbInertia.RealtimeTest do
  use ExUnit.Case, async: true

  alias NbInertia.Realtime

  # Test serializer module
  defmodule TestSerializer do
    def serialize(data, _opts) do
      %{id: data.id, name: String.upcase(data.name)}
    end
  end

  # Serializer that raises
  defmodule BrokenSerializer do
    def serialize(_data, _opts) do
      raise "serialization failed"
    end
  end

  # Mock endpoint that captures broadcast calls
  defmodule MockEndpoint do
    def broadcast(topic, event, payload) do
      send(self(), {:broadcast, topic, event, payload})
      :ok
    end

    def broadcast_from(pid, topic, event, payload) do
      send(self(), {:broadcast_from, pid, topic, event, payload})
      :ok
    end
  end

  describe "serialize_payload/1" do
    test "passes through plain values unchanged" do
      payload = %{name: "Alice", count: 42, active: true}
      assert Realtime.serialize_payload(payload) == payload
    end

    test "serializes {Serializer, data} tuples" do
      payload = %{user: {TestSerializer, %{id: 1, name: "alice"}}}
      result = Realtime.serialize_payload(payload)

      assert result == %{user: %{id: 1, name: "ALICE"}}
    end

    test "serializes {Serializer, data, opts} tuples" do
      payload = %{user: {TestSerializer, %{id: 1, name: "bob"}, []}}
      result = Realtime.serialize_payload(payload)

      assert result == %{user: %{id: 1, name: "BOB"}}
    end

    test "handles mixed plain and serialized values" do
      payload = %{
        user: {TestSerializer, %{id: 1, name: "charlie"}},
        timestamp: ~U[2024-01-01 00:00:00Z],
        count: 5
      }

      result = Realtime.serialize_payload(payload)

      assert result.user == %{id: 1, name: "CHARLIE"}
      assert result.timestamp == ~U[2024-01-01 00:00:00Z]
      assert result.count == 5
    end

    test "raises descriptive error when serializer fails" do
      payload = %{user: {BrokenSerializer, %{id: 1}}}

      assert_raise RuntimeError, ~r/NbInertia\.Realtime: serializer.*BrokenSerializer.*failed/, fn ->
        Realtime.serialize_payload(payload)
      end
    end
  end

  describe "broadcast/4" do
    test "broadcasts with keyword list payload" do
      Realtime.broadcast(MockEndpoint, "chat:1", "message_created",
        message: "Hello",
        user_id: 1
      )

      assert_received {:broadcast, "chat:1", "message_created", %{message: "Hello", user_id: 1}}
    end

    test "broadcasts with map payload" do
      Realtime.broadcast(MockEndpoint, "chat:1", "typing", %{user_id: 1, is_typing: true})

      assert_received {:broadcast, "chat:1", "typing", %{user_id: 1, is_typing: true}}
    end

    test "serializes tuple values in payload" do
      Realtime.broadcast(MockEndpoint, "chat:1", "message_created",
        message: {TestSerializer, %{id: 1, name: "hello"}}
      )

      assert_received {:broadcast, "chat:1", "message_created", %{message: %{id: 1, name: "HELLO"}}}
    end
  end

  describe "broadcast_from/4" do
    test "broadcasts excluding sender" do
      socket = %{endpoint: MockEndpoint}

      Realtime.broadcast_from(socket, "chat:1", "typing",
        user_id: 1,
        is_typing: true
      )

      assert_received {:broadcast_from, _pid, "chat:1", "typing", %{user_id: 1, is_typing: true}}
    end

    test "serializes tuple values" do
      socket = %{endpoint: MockEndpoint}

      Realtime.broadcast_from(socket, "chat:1", "message_created",
        message: {TestSerializer, %{id: 1, name: "world"}}
      )

      assert_received {:broadcast_from, _pid, "chat:1", "message_created",
                        %{message: %{id: 1, name: "WORLD"}}}
    end
  end

  describe "use NbInertia.Realtime" do
    defmodule TestContext do
      use NbInertia.Realtime, endpoint: NbInertia.RealtimeTest.MockEndpoint
    end

    test "defines broadcast/3" do
      TestContext.broadcast("chat:1", "event", message: "test")
      assert_received {:broadcast, "chat:1", "event", %{message: "test"}}
    end

    test "defines broadcast_from/4" do
      socket = %{endpoint: MockEndpoint}
      TestContext.broadcast_from(socket, "chat:1", "event", message: "test")
      assert_received {:broadcast_from, _pid, "chat:1", "event", %{message: "test"}}
    end
  end
end
