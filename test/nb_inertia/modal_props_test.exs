defmodule NbInertia.ModalPropsTest do
  use ExUnit.Case, async: false

  defmodule UserSerializer do
    use NbSerializer.Serializer

    schema do
      field(:first_name, :string)
    end
  end

  defmodule OptsEchoSerializer do
    def serialize(data, opts) do
      %{data: data, opts: opts}
    end
  end

  setup do
    previous = Application.get_env(:nb_inertia, :camelize_props)

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:nb_inertia, :camelize_props)
      else
        Application.put_env(:nb_inertia, :camelize_props, previous)
      end
    end)
  end

  test "camelizes top-level modal prop keys when enabled" do
    Application.put_env(:nb_inertia, :camelize_props, true)

    assert NbInertia.Controller.build_modal_props(
             edited_user: {UserSerializer, %{first_name: "Ada"}}
           ) == %{editedUser: %{firstName: "Ada"}}
  end

  test "keeps top-level modal prop keys unchanged when camelization is disabled" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    assert NbInertia.Controller.build_modal_props(
             edited_user: {UserSerializer, %{first_name: "Ada"}}
           ) == %{edited_user: %{first_name: "Ada"}}
  end

  test "passes through non-serializer tuples unchanged" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    assert NbInertia.Controller.build_modal_props(status: {:ok, %{id: 1}}) == %{
             status: {:ok, %{id: 1}}
           }
  end

  test "supports helper tuples with nested serializer opts" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    result =
      NbInertia.Controller.build_modal_props(
        payload: {OptsEchoSerializer, "value", opts: [scope: :full]}
      )

    assert result[:payload][:data] == "value"
    assert result[:payload][:opts][:scope] == :full
    assert result[:payload][:opts][:camelize] == false
    assert result[:payload][:opts][:keep_raw_markers] == true
  end
end
