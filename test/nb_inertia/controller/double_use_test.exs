defmodule NbInertia.Controller.DoubleUseTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  test "using the controller twice does not duplicate generated page clauses" do
    module = Module.concat(__MODULE__, "Fixture#{System.unique_integer([:positive])}")

    source = """
    defmodule #{inspect(module)} do
      use NbInertia.Controller
      use NbInertia.Controller

      inertia_page :index do
        prop :message, :string
      end
    end
    """

    warnings = capture_io(:stderr, fn -> Code.compile_string(source) end)

    refute warnings =~ "redundant"
    # The module is generated dynamically to exercise its generated functions.
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    assert apply(module, :page, [:index]) == "Index"
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    assert %{component: "Index"} = apply(module, :inertia_page_config, [:index])
  end
end
