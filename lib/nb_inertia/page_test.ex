defmodule NbInertia.PageTest do
  @moduledoc """
  Test helpers for NbInertia.Page modules.

  Provides utilities for unit testing Page module `mount/2` and `action/3`
  callbacks directly, as well as page-aware assertions that work with Page
  module references.

  ## Usage

  Import in your test modules:

      defmodule MyAppWeb.UsersPageTest do
        use ExUnit.Case
        import NbInertia.PageTest

        test "mount returns users" do
          conn = Plug.Test.conn(:get, "/users")
          props = mount_page(MyAppWeb.UsersPage.Index, conn)
          assert Map.has_key?(props, :users)
        end
      end

  Or use the `__using__` macro for a convenient setup that also imports
  the standard `NbInertia.TestHelpers`:

      defmodule MyAppWeb.UsersPageTest do
        use NbInertia.PageTest

        test "mount returns users" do
          conn = Plug.Test.conn(:get, "/users")
          props = mount_page(MyAppWeb.UsersPage.Index, conn)
          assert Map.has_key?(props, :users)
        end
      end
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Plug.Test
      import NbInertia.TestHelpers
      import NbInertia.PageTest
    end
  end

  import ExUnit.Assertions

  # ─────────────────────────────────────────────────────────────────────────────
  # Unit Test Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  @doc """
  Calls a Page module's `mount/2` callback directly and returns the resolved props map.

  This lets you unit test `mount/2` without going through the full HTTP stack.
  Handles both return types (map and conn pipeline) and resolves `from:` and
  `default:` DSL props.

  ## Examples

      # Basic usage
      props = mount_page(MyAppWeb.UsersPage.Index, conn)
      assert props[:users] == []

      # With params
      props = mount_page(MyAppWeb.UsersPage.Show, conn, %{"id" => "1"})
      assert props[:user].id == 1

      # With conn that has assigns (for from: props)
      conn = Plug.Test.conn(:get, "/") |> Plug.Conn.assign(:locale, "en")
      props = mount_page(MyAppWeb.DashboardPage, conn)
      assert props[:locale] == "en"
  """
  @spec mount_page(module(), Plug.Conn.t(), map()) :: map()
  def mount_page(page_module, conn, params \\ %{}) do
    validate_page_module!(page_module)

    result = page_module.mount(conn, params)

    case result do
      %Plug.Conn{} = returned_conn ->
        # Check for redirect
        if redirected?(returned_conn) do
          raise "mount/2 returned a redirect. Use call_mount/3 to handle redirects."
        end

        # Extract props from conn.private[:nb_inertia_page_props]
        page_props = returned_conn.private[:nb_inertia_page_props] || %{}
        dsl_props = page_module.__inertia_props__()
        apply_from_and_defaults(returned_conn, page_props, dsl_props)

      %{} = props_map ->
        dsl_props = page_module.__inertia_props__()
        apply_from_and_defaults(conn, props_map, dsl_props)
    end
  end

  @doc """
  Calls a Page module's `mount/2` callback and returns the raw result.

  Unlike `mount_page/3`, this returns the raw result from `mount/2` without
  resolving DSL props. Use this when you need to handle redirects or inspect
  the conn directly.

  Returns `{:ok, map()}` for props, `{:ok, Plug.Conn.t()}` for conn returns,
  or `{:redirect, Plug.Conn.t()}` for redirects.

  ## Examples

      # Normal props return
      {:ok, props} = call_mount(MyAppWeb.UsersPage.Index, conn)

      # Redirect return
      {:redirect, conn} = call_mount(MyAppWeb.UsersPage.Show, conn, %{"id" => "bad"})
  """
  @spec call_mount(module(), Plug.Conn.t(), map()) ::
          {:ok, map()} | {:ok, Plug.Conn.t()} | {:redirect, Plug.Conn.t()}
  def call_mount(page_module, conn, params \\ %{}) do
    validate_page_module!(page_module)

    case page_module.mount(conn, params) do
      %Plug.Conn{} = returned_conn ->
        if redirected?(returned_conn) do
          {:redirect, returned_conn}
        else
          {:ok, returned_conn}
        end

      %{} = props_map ->
        {:ok, props_map}
    end
  end

  @doc """
  Calls a Page module's `action/3` callback directly.

  Returns the raw result from `action/3`: a `%Plug.Conn{}` for redirects or
  `{:error, term}` for validation errors.

  ## Examples

      # Successful action (redirect)
      conn = call_action(MyAppWeb.UsersPage.New, conn, %{"user" => user_params}, :create)
      assert redirected_to(conn) =~ "/users/"

      # Failed action (validation error)
      {:error, errors} = call_action(MyAppWeb.UsersPage.Edit, conn, %{}, :update)
      assert errors[:name] == ["is required"]
  """
  @spec call_action(module(), Plug.Conn.t(), map(), atom()) :: Plug.Conn.t() | {:error, term()}
  def call_action(page_module, conn, params, verb) do
    validate_page_module!(page_module)

    unless page_module.__inertia_has_action__() do
      raise ArgumentError,
            "#{inspect(page_module)} does not define action/3"
    end

    page_module.action(conn, params, verb)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Page-Aware Assertions
  # ─────────────────────────────────────────────────────────────────────────────

  @doc """
  Asserts that the response rendered a specific Page module.

  Accepts a Page module, and checks that the response's Inertia component matches
  the module's `__inertia_component__/0` value. Also checks `conn.private[:nb_inertia_page_module]`
  if available.

  This does NOT replace the existing `NbInertia.TestHelpers.assert_inertia_page/2` which
  works with string and atom component names. Use this when you want to assert against
  a specific Page module reference.

  ## Examples

      conn = inertia_get(conn, ~p"/users")
      assert_page_module(conn, MyAppWeb.UsersPage.Index)
  """
  @spec assert_page_module(Plug.Conn.t(), module()) :: true
  def assert_page_module(conn, expected_module) when is_atom(expected_module) do
    validate_page_module!(expected_module)

    expected_component = expected_module.__inertia_component__()
    actual_component = get_inertia_component(conn)

    # Check component name matches
    assert actual_component == expected_component,
           """
           Expected Inertia page to be #{inspect(expected_module)} \
           (component: #{inspect(expected_component)}), \
           but the rendered component was #{inspect(actual_component)}.

           Available props: #{inspect(Map.keys(get_inertia_props(conn) || %{}))}
           """

    # If the page module is stored on the conn (when going through PageController),
    # verify that too
    case Map.get(conn.private, :nb_inertia_page_module) do
      nil ->
        # Not going through PageController, component match is sufficient
        :ok

      ^expected_module ->
        :ok

      other_module ->
        flunk("""
        Expected page module to be #{inspect(expected_module)}, \
        but conn.private[:nb_inertia_page_module] was #{inspect(other_module)}.
        """)
    end

    true
  end

  @doc """
  Asserts that the response is a modal for a specific Page module.

  Combines `assert_page_module/2` with modal header assertions.

  ## Options

    - `:base_url` - Assert that the modal's base URL matches (optional)
    - `:config` - Assert that the modal config contains specific keys (optional)

  ## Examples

      conn = inertia_get(conn, ~p"/users/1")
      assert_page_modal(conn, MyAppWeb.UsersPage.Show)
      assert_page_modal(conn, MyAppWeb.UsersPage.Show, config: %{size: "lg"})
  """
  @spec assert_page_modal(Plug.Conn.t(), module(), keyword()) :: true
  def assert_page_modal(conn, expected_module, opts \\ []) do
    # First assert the page module
    assert_page_module(conn, expected_module)

    # Then assert modal headers using the existing TestHelpers logic
    modal_header =
      conn
      |> Plug.Conn.get_resp_header("x-inertia-modal")
      |> List.first()

    assert modal_header == "true",
           """
           Expected response to be a modal for #{inspect(expected_module)}, \
           but x-inertia-modal header was #{inspect(modal_header)}.

           The page component matched, but the response is not a modal response.
           """

    if base_url = Keyword.get(opts, :base_url) do
      actual_base_url =
        conn
        |> Plug.Conn.get_resp_header("x-inertia-modal-base-url")
        |> List.first()

      assert actual_base_url == base_url,
             """
             Expected modal base URL to be #{inspect(base_url)}, \
             but got #{inspect(actual_base_url)}.
             """
    end

    if expected_config = Keyword.get(opts, :config) do
      config_json =
        conn
        |> Plug.Conn.get_resp_header("x-inertia-modal-config")
        |> List.first()

      actual_config =
        if config_json do
          Jason.decode!(config_json)
        else
          %{}
        end

      for {key, value} <- expected_config do
        str_key = to_string(key)

        assert Map.get(actual_config, str_key) == value,
               """
               Expected modal config #{inspect(key)} to be #{inspect(value)}, \
               but got #{inspect(Map.get(actual_config, str_key))}.

               Full config: #{inspect(actual_config)}
               """
      end
    end

    true
  end

  @doc """
  Returns the props map from the Inertia page response.

  Useful for inspecting all props after a request through the full stack.

  ## Examples

      conn = inertia_get(conn, ~p"/users")
      props = get_page_props(conn)
      assert length(props[:users]) == 3
  """
  @spec get_page_props(Plug.Conn.t()) :: map() | nil
  def get_page_props(conn) do
    get_inertia_props(conn)
  end

  @doc """
  Returns the Inertia component name from the response.

  ## Examples

      conn = inertia_get(conn, ~p"/users")
      assert get_page_component(conn) == "Users/Index"
  """
  @spec get_page_component(Plug.Conn.t()) :: String.t() | nil
  def get_page_component(conn) do
    get_inertia_component(conn)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Private Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  defp validate_page_module!(module) do
    unless Code.ensure_loaded?(module) do
      raise ArgumentError, "Module #{inspect(module)} could not be loaded"
    end

    unless function_exported?(module, :__inertia_page__, 0) do
      raise ArgumentError, """
      #{inspect(module)} is not a Page module.

      Expected a module that uses NbInertia.Page:

          defmodule #{inspect(module)} do
            use NbInertia.Page

            prop :data, :map

            def mount(_conn, _params), do: %{data: %{}}
          end
      """
    end
  end

  defp redirected?(%Plug.Conn{status: status}) when is_integer(status) and status in 301..303,
    do: true

  defp redirected?(_conn), do: false

  defp get_inertia_component(conn) do
    page = conn.private[:inertia_page] || %{}
    page[:component]
  end

  defp get_inertia_props(conn) do
    page = conn.private[:inertia_page] || %{}
    page[:props]
  end

  # Applies `from:` and `default:` DSL options for props not returned by mount/2.
  # This is a simplified version of the same logic in PageController.
  defp apply_from_and_defaults(conn, props_map, dsl_props) do
    Enum.reduce(dsl_props, props_map, fn prop_config, acc ->
      name = prop_config.name
      opts = prop_config[:opts] || []

      if Map.has_key?(acc, name) do
        # Prop was explicitly provided by mount/2, don't override
        acc
      else
        from = Keyword.get(opts, :from)
        default = Keyword.get(opts, :default, :__no_default__)

        cond do
          # from: :assigns -- pull from conn.assigns using the prop name as the key
          from == :assigns ->
            Map.put(acc, name, Map.get(conn.assigns, name))

          # from: :other_key -- pull from conn.assigns using the specified key
          is_atom(from) and not is_nil(from) ->
            Map.put(acc, name, Map.get(conn.assigns, from))

          # default: value -- use the default value
          default != :__no_default__ ->
            Map.put(acc, name, default)

          true ->
            acc
        end
      end
    end)
  end
end
