defmodule NbInertia.TestHelpers do
  @moduledoc """
  Test helpers for testing Inertia.js pages in Phoenix applications.

  This module provides convenient functions for making Inertia requests and asserting
  on Inertia responses in your controller tests.

  ## Usage

  Import this module in your test support modules:

      # In test/support/conn_case.ex
      defmodule MyAppWeb.ConnCase do
        use ExUnit.CaseTemplate

        using do
          quote do
            import Plug.Conn
            import Phoenix.ConnTest
            import NbInertia.TestHelpers

            @endpoint MyAppWeb.Endpoint
          end
        end
      end

  Then use the helpers in your tests:

      test "renders posts index", %{conn: conn} do
        post = insert(:post, title: "Hello World")
        conn = inertia_get(conn, ~p"/posts")

        assert_inertia_page(conn, "Posts/Index")
        assert_inertia_props(conn, [:posts, :total_count])
        assert_inertia_prop(conn, :total_count, 1)
      end

  ## Inertia Request Helpers

  Use `inertia_get/2`, `inertia_post/3`, etc. to make Inertia requests that include
  the required `X-Inertia` header.

  ## Assertion Helpers

  - `assert_inertia_page/2` - Assert that a specific component was rendered
  - `assert_inertia_props/2` - Assert that specific props are present
  - `assert_inertia_prop/3` - Assert a specific prop value
  - `refute_inertia_prop/2` - Assert a prop is not present
  """

  import ExUnit.Assertions
  import Plug.Conn

  @doc """
  Adds Inertia headers to a connection for testing.

  Use this function before making HTTP requests in your controller tests to simulate
  Inertia.js requests. Then use Phoenix.ConnTest's HTTP verbs (get, post, etc.) to
  actually make the request.

  ## Examples

      # In your tests:
      conn =
        build_conn()
        |> with_inertia_headers()
        |> get(~p"/posts")

      assert_inertia_page(conn, "Posts/Index")

      # Or for a quick helper, you can define in your ConnCase:
      def inertia_get(conn, path) do
        conn
        |> with_inertia_headers()
        |> get(path)
      end
  """
  @spec with_inertia_headers(Plug.Conn.t()) :: Plug.Conn.t()
  def with_inertia_headers(conn) do
    conn
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", "1.0")
  end

  @doc """
  Helper macro for making GET requests with Inertia headers.

  ## Examples

      conn = inertia_get(conn, ~p"/posts")
      assert_inertia_page(conn, "Posts/Index")
  """
  defmacro inertia_get(conn, path) do
    quote do
      unquote(conn)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", "1.0")
      |> get(unquote(path))
    end
  end

  @doc """
  Helper macro for making POST requests with Inertia headers.

  ## Examples

      conn = inertia_post(conn, ~p"/posts", %{post: %{title: "Hello"}})
  """
  defmacro inertia_post(conn, path, params \\ quote(do: %{})) do
    quote do
      unquote(conn)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", "1.0")
      |> post(unquote(path), unquote(params))
    end
  end

  @doc """
  Helper macro for making PUT requests with Inertia headers.

  ## Examples

      conn = inertia_put(conn, ~p"/posts/\#{post.id}", %{post: %{title: "Updated"}})
  """
  defmacro inertia_put(conn, path, params \\ quote(do: %{})) do
    quote do
      unquote(conn)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", "1.0")
      |> put(unquote(path), unquote(params))
    end
  end

  @doc """
  Helper macro for making PATCH requests with Inertia headers.

  ## Examples

      conn = inertia_patch(conn, ~p"/posts/\#{post.id}", %{post: %{title: "Patched"}})
  """
  defmacro inertia_patch(conn, path, params \\ quote(do: %{})) do
    quote do
      unquote(conn)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", "1.0")
      |> patch(unquote(path), unquote(params))
    end
  end

  @doc """
  Helper macro for making DELETE requests with Inertia headers.

  ## Examples

      conn = inertia_delete(conn, ~p"/posts/\#{post.id}")
  """
  defmacro inertia_delete(conn, path) do
    quote do
      unquote(conn)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", "1.0")
      |> delete(unquote(path))
    end
  end

  @doc """
  Asserts that the response renders a specific Inertia component.

  ## Examples

      assert_inertia_page(conn, "Posts/Index")
      assert_inertia_page(conn, "Users/Show")
  """
  @spec assert_inertia_page(Plug.Conn.t(), String.t()) :: true
  def assert_inertia_page(conn, expected_component) do
    component = get_inertia_component(conn)

    assert component == expected_component,
           """
           Expected Inertia component to be #{inspect(expected_component)}, but got #{inspect(component)}.

           Available props: #{inspect(Map.keys(get_inertia_props(conn) || %{}))}
           """

    true
  end

  @doc """
  Asserts that specific props are present in the Inertia response.

  This checks that the keys exist in the props, but doesn't validate their values.

  ## Examples

      assert_inertia_props(conn, [:posts, :total_count])
      assert_inertia_props(conn, [:user, :settings])
  """
  @spec assert_inertia_props(Plug.Conn.t(), list(atom() | String.t())) :: true
  def assert_inertia_props(conn, expected_prop_keys) when is_list(expected_prop_keys) do
    props = get_inertia_props(conn) || %{}
    prop_keys = Map.keys(props) |> Enum.map(&to_prop_key/1) |> MapSet.new()

    expected_keys = Enum.map(expected_prop_keys, &to_prop_key/1)

    missing_keys =
      expected_keys
      |> Enum.reject(&MapSet.member?(prop_keys, &1))

    assert Enum.empty?(missing_keys),
           """
           Expected props #{inspect(expected_prop_keys)} to be present, but missing: #{inspect(missing_keys)}.

           Available props: #{inspect(Map.keys(props))}
           """

    true
  end

  @doc """
  Asserts that a specific prop has the expected value.

  ## Examples

      assert_inertia_prop(conn, :total_count, 5)
      assert_inertia_prop(conn, :user, %{id: 1, name: "John"})
      assert_inertia_prop(conn, "totalCount", 5)  # Works with camelCase too
  """
  @spec assert_inertia_prop(Plug.Conn.t(), atom() | String.t(), any()) :: true
  def assert_inertia_prop(conn, prop_key, expected_value) do
    props = get_inertia_props(conn) || %{}
    prop_key = to_prop_key(prop_key)

    actual_value =
      case Map.fetch(props, prop_key) do
        {:ok, value} ->
          value

        :error ->
          # Try the other case (atom vs string or camelCase vs snake_case)
          alternate_key = find_alternate_key(props, prop_key)

          case alternate_key do
            nil ->
              flunk("""
              Prop #{inspect(prop_key)} not found in Inertia props.

              Available props: #{inspect(Map.keys(props))}
              """)

            key ->
              Map.fetch!(props, key)
          end
      end

    assert actual_value == expected_value,
           """
           Expected prop #{inspect(prop_key)} to equal #{inspect(expected_value)}, but got #{inspect(actual_value)}.
           """

    true
  end

  @doc """
  Asserts that a specific prop is NOT present in the Inertia response.

  ## Examples

      refute_inertia_prop(conn, :password)
      refute_inertia_prop(conn, :internal_data)
  """
  @spec refute_inertia_prop(Plug.Conn.t(), atom() | String.t()) :: true
  def refute_inertia_prop(conn, prop_key) do
    props = get_inertia_props(conn) || %{}
    prop_key = to_prop_key(prop_key)

    has_prop = Map.has_key?(props, prop_key) || find_alternate_key(props, prop_key) != nil

    refute has_prop,
           """
           Expected prop #{inspect(prop_key)} to NOT be present, but it was found.

           Props: #{inspect(props)}
           """

    true
  end

  @doc """
  Asserts that specific shared props are present in the Inertia response.

  Shared props are those defined via `inertia_shared` in controllers or SharedProps modules.
  This is useful for testing that shared props are correctly injected across all pages.

  ## Examples

      conn = inertia_get(conn, ~p"/dashboard")
      assert_shared_props(conn, [:current_user, :flash])
  """
  @spec assert_shared_props(Plug.Conn.t(), list(atom() | String.t())) :: true
  def assert_shared_props(conn, expected_prop_keys) when is_list(expected_prop_keys) do
    # Shared props are part of the regular props, so we reuse assert_inertia_props
    assert_inertia_props(conn, expected_prop_keys)
  end

  @doc """
  Asserts that a specific shared prop has the expected value.

  ## Examples

      conn = inertia_get(conn, ~p"/users")
      assert_shared_prop(conn, :app_name, "MyApp")
      assert_shared_prop(conn, :current_user, %{id: 1, name: "Alice"})
  """
  @spec assert_shared_prop(Plug.Conn.t(), atom() | String.t(), any()) :: true
  def assert_shared_prop(conn, prop_key, expected_value) do
    # Shared props are part of the regular props, so we reuse assert_inertia_prop
    assert_inertia_prop(conn, prop_key, expected_value)
  end

  @doc """
  Asserts that a specific shared prop is NOT present in the Inertia response.

  Useful for testing conditional shared props (e.g., admin-only data).

  ## Examples

      conn =
        conn
        |> assign(:current_user, regular_user)
        |> inertia_get(~p"/dashboard")

      # Admin data should not be present for regular users
      refute_shared_prop(conn, :admin_settings)
  """
  @spec refute_shared_prop(Plug.Conn.t(), atom() | String.t()) :: true
  def refute_shared_prop(conn, prop_key) do
    # Shared props are part of the regular props, so we reuse refute_inertia_prop
    refute_inertia_prop(conn, prop_key)
  end

  @doc """
  Asserts that shared props from a specific SharedProps module are present.

  This extracts the expected prop names from the module's `inertia_shared` definition
  and verifies they are all present in the response.

  ## Examples

      assert_shared_module_props(conn, MyAppWeb.InertiaShared.Auth)
      # Checks that all props defined in Auth module are present
  """
  @spec assert_shared_module_props(Plug.Conn.t(), module()) :: true
  def assert_shared_module_props(conn, shared_module) do
    if function_exported?(shared_module, :__inertia_shared_props__, 0) do
      expected_props =
        shared_module.__inertia_shared_props__()
        |> Enum.map(& &1.name)

      assert_shared_props(conn, expected_props)
    else
      flunk("""
      Module #{inspect(shared_module)} does not appear to be a SharedProps module.

      Expected it to define __inertia_shared_props__/0.

      Make sure you have:
        use NbInertia.SharedProps
        inertia_shared do
          prop :my_prop, :type
        end
      """)
    end
  end

  @doc """
  Extracts shared props that were applied to the current request.

  Returns a map of shared prop keys and their values.
  Note: There's no way to distinguish shared props from page props at runtime,
  so this returns all props (which includes shared props).

  ## Examples

      shared_props = get_shared_props(conn)
      assert Map.has_key?(shared_props, :current_user)
  """
  @spec get_shared_props(Plug.Conn.t()) :: map()
  def get_shared_props(conn) do
    # Since shared props are merged into the regular props,
    # we return all props (shared + page props)
    get_inertia_props(conn)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Modal Assertions
  # ─────────────────────────────────────────────────────────────────────────────

  @doc """
  Asserts that the response is a modal response.

  Checks for the `x-inertia-modal` response header set by `render_inertia_modal/4`.

  ## Options

    - `:base_url` - Assert that the modal's base URL matches (optional)
    - `:config` - Assert that the modal config contains specific keys (optional)

  ## Examples

      conn = inertia_get(conn, ~p"/users/1")
      assert_inertia_modal(conn)
      assert_inertia_modal(conn, base_url: "/users")
      assert_inertia_modal(conn, config: %{size: "lg"})
  """
  @spec assert_inertia_modal(Plug.Conn.t(), keyword()) :: true
  def assert_inertia_modal(conn, opts \\ []) do
    modal_header =
      conn
      |> Plug.Conn.get_resp_header("x-inertia-modal")
      |> List.first()

    assert modal_header == "true",
           """
           Expected response to be a modal response (x-inertia-modal: true),
           but header was #{inspect(modal_header)}.

           Response headers: #{inspect(conn.resp_headers)}
           """

    if base_url = Keyword.get(opts, :base_url) do
      actual_base_url =
        conn
        |> Plug.Conn.get_resp_header("x-inertia-modal-base-url")
        |> List.first()

      assert actual_base_url == base_url,
             """
             Expected modal base URL to be #{inspect(base_url)},
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
               Expected modal config #{inspect(key)} to be #{inspect(value)},
               but got #{inspect(Map.get(actual_config, str_key))}.

               Full config: #{inspect(actual_config)}
               """
      end
    end

    true
  end

  @doc """
  Refutes that the response is a modal response.

  ## Examples

      conn = inertia_get(conn, ~p"/users")
      refute_inertia_modal(conn)
  """
  @spec refute_inertia_modal(Plug.Conn.t()) :: true
  def refute_inertia_modal(conn) do
    modal_header =
      conn
      |> Plug.Conn.get_resp_header("x-inertia-modal")
      |> List.first()

    refute modal_header == "true",
           """
           Expected response to NOT be a modal response,
           but x-inertia-modal header was "true".
           """

    true
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flash Assertions
  # ─────────────────────────────────────────────────────────────────────────────

  @doc """
  Asserts that specific flash data was set on the connection.

  Checks `conn.private[:nb_inertia_flash]` for the given key.

  ## Examples

      conn =
        conn
        |> NbInertia.Flash.inertia_flash(:message, "Success!")

      assert_inertia_flash(conn, :message, "Success!")
      assert_inertia_flash(conn, "message", "Success!")
  """
  @spec assert_inertia_flash(Plug.Conn.t(), atom() | String.t(), any()) :: true
  def assert_inertia_flash(conn, key, expected_value) do
    flash = conn.private[:nb_inertia_flash] || %{}
    str_key = to_string(key)

    actual_value = Map.get(flash, str_key)

    assert actual_value == expected_value,
           """
           Expected Inertia flash #{inspect(key)} to be #{inspect(expected_value)},
           but got #{inspect(actual_value)}.

           Flash data: #{inspect(flash)}
           """

    true
  end

  @doc """
  Asserts that a flash key is present (regardless of value).

  ## Examples

      conn =
        conn
        |> NbInertia.Flash.inertia_flash(:message, "Hello!")

      assert_inertia_flash(conn, :message)
  """
  @spec assert_inertia_flash(Plug.Conn.t(), atom() | String.t()) :: true
  def assert_inertia_flash(conn, key) do
    flash = conn.private[:nb_inertia_flash] || %{}
    str_key = to_string(key)

    assert Map.has_key?(flash, str_key),
           """
           Expected Inertia flash key #{inspect(key)} to be present.

           Flash data: #{inspect(flash)}
           """

    true
  end

  @doc """
  Refutes that a flash key is present.

  ## Examples

      refute_inertia_flash(conn, :error)
  """
  @spec refute_inertia_flash(Plug.Conn.t(), atom() | String.t()) :: true
  def refute_inertia_flash(conn, key) do
    flash = conn.private[:nb_inertia_flash] || %{}
    str_key = to_string(key)

    refute Map.has_key?(flash, str_key),
           """
           Expected Inertia flash key #{inspect(key)} to NOT be present.

           Flash data: #{inspect(flash)}
           """

    true
  end

  @doc """
  Adds modal request headers to a connection for testing.

  Simulates a request from a ModalLink component.

  ## Examples

      conn =
        build_conn()
        |> with_inertia_headers()
        |> with_modal_headers()
        |> get(~p"/users/1")

      assert_inertia_modal(conn)
  """
  @spec with_modal_headers(Plug.Conn.t()) :: Plug.Conn.t()
  def with_modal_headers(conn) do
    put_req_header(conn, "x-inertia-modal-request", "true")
  end

  # Private helpers

  defp get_inertia_component(conn) do
    page = conn.private[:inertia_page] || %{}
    page[:component]
  end

  defp get_inertia_props(conn) do
    page = conn.private[:inertia_page] || %{}
    page[:props]
  end

  defp to_prop_key(key) when is_atom(key), do: key
  defp to_prop_key(key) when is_binary(key), do: key
  defp to_prop_key(key), do: to_string(key)

  # Try to find the prop key in alternate forms (atom/string, camelCase/snake_case)
  defp find_alternate_key(props, prop_key) when is_atom(prop_key) do
    string_key = Atom.to_string(prop_key)
    snake_key = camel_to_snake(string_key)
    camel_key = snake_to_camel(string_key)

    cond do
      Map.has_key?(props, string_key) -> string_key
      Map.has_key?(props, camel_key) -> camel_key
      Map.has_key?(props, String.to_atom(camel_key)) -> String.to_atom(camel_key)
      Map.has_key?(props, snake_key) -> snake_key
      Map.has_key?(props, String.to_atom(snake_key)) -> String.to_atom(snake_key)
      true -> nil
    end
  end

  defp find_alternate_key(props, prop_key) when is_binary(prop_key) do
    atom_key =
      try do
        String.to_existing_atom(prop_key)
      rescue
        ArgumentError -> nil
      end

    snake_key = camel_to_snake(prop_key)

    cond do
      atom_key && Map.has_key?(props, atom_key) -> atom_key
      Map.has_key?(props, snake_key) -> snake_key
      true -> nil
    end
  end

  defp snake_to_camel(string) do
    string
    |> String.split("_")
    |> Enum.with_index()
    |> Enum.map_join(fn
      {word, 0} -> word
      {word, _} -> String.capitalize(word)
    end)
  end

  defp camel_to_snake(string) do
    string
    |> String.replace(~r/([A-Z])/, "_\\1")
    |> String.downcase()
    |> String.trim_leading("_")
  end
end
