if Code.ensure_loaded?(Wallaby.Browser) do
  defmodule NbInertia.WallabyHelpers do
    @moduledoc """
    Wallaby browser-level test helpers for Inertia.js applications.

    Provides helpers for asserting on Inertia page state, modals, flash data,
    and forms in end-to-end tests using Wallaby.

    ## Setup

    Add Wallaby to your dependencies:

        {:wallaby, "~> 0.30", only: :test}

    Import in your feature case:

        defmodule MyAppWeb.FeatureCase do
          use ExUnit.CaseTemplate

          using do
            quote do
              use Wallaby.Feature
              import NbInertia.WallabyHelpers
            end
          end
        end

    ## Usage

        feature "viewing a user in a modal", %{session: session} do
          session
          |> visit("/users")
          |> assert_inertia_component("UsersIndex")
          |> click_modal_link("Alice")
          |> assert_modal_open()
          |> assert_modal_text("Alice")
          |> close_modal()
          |> refute_modal_open()
        end

    ## Pipelining

    Assertion helpers (`assert_*`, `refute_*`, `click_modal_link`, `close_modal`,
    `dismiss_modal`, `fill_inertia_form`, `submit_form`, `trigger_blur`,
    `inertia_visit`, `wait_for_inertia`) return the session for pipelining.

    Data extraction helpers (`inertia_page_data`, `inertia_component`,
    `inertia_props`, `inertia_prop`, `inertia_flash`) return the extracted value
    (similar to `Wallaby.Browser.current_path/1`).
    """

    import ExUnit.Assertions

    require Wallaby.Browser
    import Wallaby.Browser, only: [execute_query: 2]

    alias Wallaby.{Browser, Query}

    # ─────────────────────────────────────────────────────────────────────────
    # JavaScript Snippets
    # ─────────────────────────────────────────────────────────────────────────

    @js_get_page_data """
    return (function() {
      var el = document.getElementById('app');
      if (!el) return null;
      var raw = el.dataset.page || el.getAttribute('data-page');
      if (raw) {
        try { return JSON.parse(raw); } catch(e) {}
      }
      return null;
    })();
    """

    @js_get_component """
    return (function() {
      var el = document.getElementById('app');
      if (!el) return null;
      var raw = el.dataset.page || el.getAttribute('data-page');
      if (raw) {
        try { return JSON.parse(raw).component; } catch(e) {}
      }
      return null;
    })();
    """

    @js_get_props """
    return (function() {
      var el = document.getElementById('app');
      if (!el) return null;
      var raw = el.dataset.page || el.getAttribute('data-page');
      if (raw) {
        try { return JSON.parse(raw).props; } catch(e) {}
      }
      return null;
    })();
    """

    @js_get_prop """
    return (function(path) {
      var el = document.getElementById('app');
      if (!el) return null;
      var raw = el.dataset.page || el.getAttribute('data-page');
      if (!raw) return null;
      var data;
      try { data = JSON.parse(raw); } catch(e) { return null; }
      if (!data || !data.props) return null;
      var parts = path.split('.');
      var val = data.props;
      for (var i = 0; i < parts.length; i++) {
        if (val == null) return null;
        val = val[parts[i]];
      }
      return val === undefined ? null : val;
    })(arguments[0]);
    """

    @js_get_flash """
    return (function() {
      var el = document.getElementById('app');
      if (!el) return null;
      var raw = el.dataset.page || el.getAttribute('data-page');
      if (!raw) return null;
      try {
        var data = JSON.parse(raw);
        return data.flash || (data.props && data.props.flash) || null;
      } catch(e) { return null; }
    })();
    """

    @js_trigger_blur """
    (function(selector) {
      var el = document.querySelector(selector);
      if (el) {
        el.dispatchEvent(new Event('blur', { bubbles: true }));
      }
    })(arguments[0]);
    """

    # ─────────────────────────────────────────────────────────────────────────
    # Page State Helpers (return extracted value, NOT session)
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Returns the full Inertia page data object.

    The returned map contains `"component"`, `"props"`, `"url"`, and `"version"` keys.

    ## Examples

        page = inertia_page_data(session)
        assert page["component"] == "Users/Index"
    """
    @spec inertia_page_data(Wallaby.Session.t()) :: map() | nil
    def inertia_page_data(session) do
      eval_js(session, @js_get_page_data)
    end

    @doc """
    Returns the current Inertia component name.

    ## Examples

        assert inertia_component(session) == "Users/Index"
    """
    @spec inertia_component(Wallaby.Session.t()) :: String.t() | nil
    def inertia_component(session) do
      eval_js(session, @js_get_component)
    end

    @doc """
    Returns all current Inertia props as a map.

    ## Examples

        props = inertia_props(session)
        assert props["user"]["name"] == "Alice"
    """
    @spec inertia_props(Wallaby.Session.t()) :: map() | nil
    def inertia_props(session) do
      eval_js(session, @js_get_props)
    end

    @doc """
    Returns a specific Inertia prop by dot-delimited path.

    ## Examples

        assert inertia_prop(session, "user.name") == "Alice"
        assert inertia_prop(session, "count") == 5
    """
    @spec inertia_prop(Wallaby.Session.t(), String.t()) :: any()
    def inertia_prop(session, path) when is_binary(path) do
      eval_js(session, @js_get_prop, [path])
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Navigation Helpers (return session for pipelining)
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Navigates to a path and waits for Inertia to mount.

    ## Examples

        session
        |> inertia_visit("/users")
        |> assert_inertia_component("Users/Index")
    """
    @spec inertia_visit(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def inertia_visit(session, path) do
      session
      |> Browser.visit(path)
      |> wait_for_inertia()
    end

    @doc """
    Waits until the Inertia app has mounted (the `#app[data-page]` element exists).

    Uses Wallaby's built-in retry mechanism via `assert_has`.

    ## Examples

        session
        |> Browser.visit("/users")
        |> wait_for_inertia()
    """
    @spec wait_for_inertia(Wallaby.Session.t()) :: Wallaby.Session.t()
    def wait_for_inertia(session) do
      Browser.assert_has(session, Query.css("#app[data-page]"))
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Page Assertions (return session for pipelining)
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Asserts the current Inertia component matches the expected name.

    ## Examples

        session
        |> assert_inertia_component("Users/Index")
        |> click(Query.link("Alice"))
    """
    @spec assert_inertia_component(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def assert_inertia_component(session, expected) do
      actual = inertia_component(session)

      assert actual == expected,
             """
             Expected Inertia component #{inspect(expected)}, but got #{inspect(actual)}.
             """

      session
    end

    @doc """
    Asserts a specific Inertia prop at the given dot-path equals the expected value.

    ## Examples

        session
        |> assert_inertia_prop("user.name", "Alice")
        |> assert_inertia_prop("count", 5)
    """
    @spec assert_inertia_prop(Wallaby.Session.t(), String.t(), any()) :: Wallaby.Session.t()
    def assert_inertia_prop(session, path, expected) do
      actual = inertia_prop(session, path)

      assert actual == expected,
             """
             Expected Inertia prop #{inspect(path)} to be #{inspect(expected)}, but got #{inspect(actual)}.
             """

      session
    end

    @doc """
    Asserts the current browser path matches the expected path.

    ## Examples

        session
        |> assert_path("/users")
        |> assert_inertia_component("Users/Index")
    """
    @spec assert_path(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def assert_path(session, expected_path) do
      actual = Browser.current_path(session)

      assert actual == expected_path,
             """
             Expected path #{inspect(expected_path)}, but got #{inspect(actual)}.
             """

      session
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Modal Helpers (return session for pipelining)
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Asserts a modal dialog is currently open.

    Checks for an element with `role="dialog"` using Wallaby's built-in retry.

    ## Examples

        session
        |> click_modal_link("View User")
        |> assert_modal_open()
    """
    @spec assert_modal_open(Wallaby.Session.t()) :: Wallaby.Session.t()
    def assert_modal_open(session) do
      Browser.assert_has(session, Query.css("[role='dialog']"))
    end

    @doc """
    Asserts no modal dialog is currently open.

    ## Examples

        session
        |> close_modal()
        |> refute_modal_open()
    """
    @spec refute_modal_open(Wallaby.Session.t()) :: Wallaby.Session.t()
    def refute_modal_open(session) do
      Browser.refute_has(session, Query.css("[role='dialog']"))
    end

    @doc """
    Clicks a ModalLink by its visible text content.

    ## Examples

        session
        |> click_modal_link("View User")
        |> assert_modal_open()
    """
    @spec click_modal_link(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def click_modal_link(session, text) do
      Browser.click(session, Query.link(text))
    end

    @doc """
    Closes the topmost modal by clicking its close button (`[aria-label="Close"]`).

    ## Examples

        session
        |> assert_modal_open()
        |> close_modal()
        |> refute_modal_open()
    """
    @spec close_modal(Wallaby.Session.t()) :: Wallaby.Session.t()
    def close_modal(session) do
      Browser.click(session, Query.css("[role='dialog'] [aria-label='Close']"))
    end

    @doc """
    Dismisses the topmost modal by pressing the Escape key.

    ## Examples

        session
        |> assert_modal_open()
        |> dismiss_modal()
        |> refute_modal_open()
    """
    @spec dismiss_modal(Wallaby.Session.t()) :: Wallaby.Session.t()
    def dismiss_modal(session) do
      Browser.send_keys(session, [:escape])
    end

    @doc """
    Asserts that the given text appears inside the topmost modal dialog.

    ## Examples

        session
        |> assert_modal_open()
        |> assert_modal_text("User Details")
    """
    @spec assert_modal_text(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def assert_modal_text(session, text) do
      Browser.find(session, Query.css("[role='dialog']"), fn dialog ->
        Browser.assert_text(dialog, text)
      end)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Flash Helpers
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Returns the Inertia flash data from the current page.

    Reads flash from the page's `flash` field or `props.flash`.

    ## Examples

        flash = inertia_flash(session)
        assert flash["message"] == "User created!"
    """
    @spec inertia_flash(Wallaby.Session.t()) :: map() | nil
    def inertia_flash(session) do
      eval_js(session, @js_get_flash)
    end

    @doc """
    Asserts a flash key is present.

    ## Examples

        session
        |> assert_inertia_flash("message")
    """
    @spec assert_inertia_flash(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def assert_inertia_flash(session, key) when is_binary(key) do
      flash = inertia_flash(session) || %{}

      assert Map.has_key?(flash, key),
             """
             Expected Inertia flash key #{inspect(key)} to be present.

             Flash data: #{inspect(flash)}
             """

      session
    end

    @doc """
    Asserts a flash key equals the expected value.

    ## Examples

        session
        |> assert_inertia_flash("message", "User created!")
    """
    @spec assert_inertia_flash(Wallaby.Session.t(), String.t(), any()) :: Wallaby.Session.t()
    def assert_inertia_flash(session, key, expected) when is_binary(key) do
      flash = inertia_flash(session) || %{}
      actual = Map.get(flash, key)

      assert actual == expected,
             """
             Expected Inertia flash #{inspect(key)} to be #{inspect(expected)}, but got #{inspect(actual)}.

             Flash data: #{inspect(flash)}
             """

      session
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Form Helpers (return session for pipelining)
    # ─────────────────────────────────────────────────────────────────────────

    @doc """
    Fills multiple form fields and triggers blur on each for precognition validation.

    Fields are specified as a keyword list of `{label_or_name, value}` pairs.

    ## Examples

        session
        |> fill_inertia_form(name: "Alice", email: "alice@example.com")
        |> submit_form(Query.button("Save"))
    """
    @spec fill_inertia_form(Wallaby.Session.t(), keyword(String.t())) :: Wallaby.Session.t()
    def fill_inertia_form(session, fields) when is_list(fields) do
      Enum.reduce(fields, session, fn {label, value}, acc ->
        query = Query.fillable_field(to_string(label))

        acc
        |> Browser.fill_in(query, with: value)
        |> Browser.send_keys(query, [:tab])
      end)
    end

    @doc """
    Clicks a submit button matching the given query.

    ## Examples

        session
        |> submit_form(Query.button("Save"))
        |> assert_path("/users")

        session
        |> submit_form(Query.css("[data-testid='user-form'] button[type='submit']"))
    """
    @spec submit_form(Wallaby.Session.t(), Wallaby.Query.t()) :: Wallaby.Session.t()
    def submit_form(session, query) do
      Browser.click(session, query)
    end

    @doc """
    Dispatches a blur event on the element matching the CSS selector.

    Useful for triggering precognition validation on a specific field.

    ## Examples

        session
        |> fill_in(Query.text_field("Email"), with: "bad")
        |> trigger_blur("#email")
    """
    @spec trigger_blur(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def trigger_blur(session, css_selector) do
      Browser.execute_script(session, @js_trigger_blur, [css_selector])
    end

    @doc """
    Asserts that error text is visible on the page.

    ## Examples

        session
        |> submit_form(Query.button("Save"))
        |> assert_form_error("can't be blank")
    """
    @spec assert_form_error(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
    def assert_form_error(session, text) do
      Browser.assert_text(session, text)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Private Helpers
    # ─────────────────────────────────────────────────────────────────────────

    defp eval_js(session, script, args \\ []) do
      ref = make_ref()
      pid = self()

      Browser.execute_script(session, script, args, fn result ->
        send(pid, {ref, result})
      end)

      receive do
        {^ref, result} -> result
      after
        5_000 -> raise "NbInertia.WallabyHelpers: JavaScript execution timed out"
      end
    end
  end
end
