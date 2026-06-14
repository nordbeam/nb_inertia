defmodule NbInertia.PropSerializerTest do
  use ExUnit.Case, async: true

  defmodule PlainStruct do
    defstruct [:id, :name]
  end

  describe "fallback implementation" do
    test "serializes URI structs without protocol errors" do
      uri = URI.parse("https://example.com/posts/1?preview=true")

      assert {:ok, ^uri} = NbInertia.PropSerializer.serialize(uri, [])
    end

    test "serializes ordinary structs without protocol errors" do
      value = %PlainStruct{id: 1, name: "Ada"}

      assert {:ok, ^value} = NbInertia.PropSerializer.serialize(value, [])
    end
  end
end
