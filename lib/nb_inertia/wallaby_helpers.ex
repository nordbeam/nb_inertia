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

  Wallaby must use the same host as your Phoenix endpoint URL host.
  For example, if your endpoint serves `http://localhost:4002`, do not point
  Wallaby at `http://127.0.0.1:4002`, or session cookies may not stick across
  Inertia redirects.

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

  @assertion_timeout 5_000
  @assertion_interval 50

  # ─────────────────────────────────────────────────────────────────────────
  # JavaScript Snippets
  # ─────────────────────────────────────────────────────────────────────────

  @js_install_state_tracker """
  return (function() {
    function readBootstrapPage() {
      var script = document.querySelector('script[data-page="app"][type="application/json"]');
      if (script && script.textContent) {
        try { return JSON.parse(script.textContent); } catch (e) {}
      }

      var el = document.getElementById('app');
      if (!el) return null;

      var raw = el.dataset.page || el.getAttribute('data-page');
      if (!raw) return null;

      try { return JSON.parse(raw); } catch (e) { return null; }
    }

    function syncFromPage(page) {
      if (!page) return;
      window.__nb_inertia_page = page;
      window.__nb_inertia_flash = page.flash || (page.props && page.props.flash) || {};
    }

    if (window.__nb_inertia_tracker_installed) {
      if (!window.__nb_inertia_page) {
        syncFromPage(readBootstrapPage());
      }

      return true;
    }

    syncFromPage(readBootstrapPage());

    document.addEventListener('inertia:navigate', function(event) {
      syncFromPage(event && event.detail && event.detail.page);
    });

    document.addEventListener('inertia:success', function(event) {
      syncFromPage(event && event.detail && event.detail.page);
    });

    document.addEventListener('inertia:flash', function(event) {
      var flash = (event && event.detail && event.detail.flash) || {};
      window.__nb_inertia_flash = flash;

      if (window.__nb_inertia_page) {
        window.__nb_inertia_page = Object.assign({}, window.__nb_inertia_page, { flash: flash });
      }
    });

    window.__nb_inertia_tracker_installed = true;
    return true;
  })();
  """

  @js_get_page_data """
  return (function() {
    if (window.__nb_inertia_page) {
      return window.__nb_inertia_page;
    }

    var historyPage = window.history && window.history.state && window.history.state.page;
    if (historyPage) {
      return historyPage;
    }

    var script = document.querySelector('script[data-page="app"][type="application/json"]');
    if (script && script.textContent) {
      try { return JSON.parse(script.textContent); } catch(e) {}
    }

    var el = document.getElementById('app');
    if (!el) return null;

    var raw = el.dataset.page || el.getAttribute('data-page');
    if (!raw) return null;

    try { return JSON.parse(raw); } catch(e) { return null; }
  })();
  """

  @js_get_component """
  return (function() {
    var script = document.querySelector('script[data-page="app"][type="application/json"]');
    if (script && script.textContent) {
      try { return JSON.parse(script.textContent).component; } catch(e) {}
    }
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
    var script = document.querySelector('script[data-page="app"][type="application/json"]');
    if (script && script.textContent) {
      try { return JSON.parse(script.textContent).props; } catch(e) {}
    }
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
    var script = document.querySelector('script[data-page="app"][type="application/json"]');
    var raw = script && script.textContent;
    if (!raw) {
      var el = document.getElementById('app');
      if (!el) return null;
      raw = el.dataset.page || el.getAttribute('data-page');
    }
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
    if (window.__nb_inertia_flash) {
      return window.__nb_inertia_flash;
    }

    if (window.__nb_inertia_page && window.__nb_inertia_page.flash) {
      return window.__nb_inertia_page.flash;
    }

    var script = document.querySelector('script[data-page="app"][type="application/json"]');
    var raw = script && script.textContent;
    if (!raw) {
      var el = document.getElementById('app');
      if (!el) return null;
      raw = el.dataset.page || el.getAttribute('data-page');
    }
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

  @js_set_password_field """
  (function(field, value) {
    var selector = 'input[type="password"][id="' + field + '"], input[type="password"][name="' + field + '"]';
    var el = document.querySelector(selector);

    if (!el) {
      return false;
    }

    var descriptor = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');

    if (descriptor && typeof descriptor.set === 'function') {
      descriptor.set.call(el, value);
    } else {
      el.value = value;
    }

    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
    el.dispatchEvent(new Event('blur', { bubbles: true }));

    return true;
  })(arguments[0], arguments[1]);
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
    ensure_inertia_state_tracker(session)
    eval_js(session, @js_get_page_data)
  end

  @doc """
  Returns the current Inertia component name.

  ## Examples

      assert inertia_component(session) == "Users/Index"
  """
  @spec inertia_component(Wallaby.Session.t()) :: String.t() | nil
  def inertia_component(session) do
    ensure_inertia_state_tracker(session)
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
    ensure_inertia_state_tracker(session)
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
    ensure_inertia_state_tracker(session)
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
    |> browser_visit(path)
    |> wait_for_inertia()
  end

  @doc """
  Waits until the Inertia app has mounted and the initial page data script exists.

  Uses Wallaby's built-in retry mechanism via `assert_has`.

  ## Examples

      session
      |> Browser.visit("/users")
      |> wait_for_inertia()
  """
  @spec wait_for_inertia(Wallaby.Session.t()) :: Wallaby.Session.t()
  def wait_for_inertia(session) do
    assert browser_has?(
             session,
             query_css("script[data-page='app'][type='application/json']", visible: false)
           )

    ensure_inertia_state_tracker(session)
    session
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
    actual =
      wait_for_expected(
        fn -> inertia_component(session) end,
        &(&1 == expected)
      )

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
    actual =
      wait_for_expected(
        fn -> inertia_prop(session, path) end,
        &(&1 == expected)
      )

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
    actual =
      wait_for_expected(
        fn -> browser_current_path(session) end,
        &(&1 == expected_path)
      )

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
    assert browser_has?(session, query_css("[role='dialog']"))
    session
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
    assert browser_has_no_css?(session, "[role='dialog']")
    session
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
    ensure_inertia_state_tracker(session)
    browser_click(session, query_link(text))
  end

  @doc """
  Clicks a button inside the currently open modal.

  Useful when the underlying page contains another button with the same label.
  """
  @spec click_modal_button(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
  def click_modal_button(session, text) do
    browser_find(session, query_css("[role='dialog']"), fn dialog ->
      browser_click(dialog, query_button(text))
    end)

    session
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
    browser_click(session, query_css("[role='dialog'] [aria-label='Close']"))
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
    browser_send_keys(session, [:escape])
  end

  @doc """
  Accepts a JavaScript confirm dialog triggered by clicking a button in the modal.

  When `expected_message` is provided, the helper also asserts on the confirm text.
  """
  @spec accept_modal_confirm(Wallaby.Session.t(), String.t()) :: Wallaby.Session.t()
  def accept_modal_confirm(session, text), do: accept_modal_confirm(session, text, nil)

  @spec accept_modal_confirm(Wallaby.Session.t(), String.t(), String.t() | nil) ::
          Wallaby.Session.t()
  def accept_modal_confirm(session, text, expected_message) do
    actual_message =
      browser_accept_confirm(session, fn current_session ->
        browser_find(current_session, query_css("[role='dialog']"), fn dialog ->
          browser_click(dialog, query_button(text))
        end)
      end)

    if expected_message do
      assert actual_message == expected_message,
             """
             Expected modal confirm message #{inspect(expected_message)}, but got #{inspect(actual_message)}.
             """
    end

    session
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
    browser_find(session, query_css("[role='dialog']"), fn dialog ->
      browser_assert_text(dialog, text)
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
    ensure_inertia_state_tracker(session)
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
      field = to_string(label)

      if password_field_name?(field) do
        browser_execute_script(acc, @js_set_password_field, [field, value])
      else
        case resolve_form_field_query(acc, field) do
          {:fillable, query} ->
            acc
            |> browser_fill_in(query, with: value)
            |> browser_send_keys(query, [:tab])

          {:password, password_field} ->
            browser_execute_script(acc, @js_set_password_field, [password_field, value])
        end
      end
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
    ensure_inertia_state_tracker(session)
    browser_click(session, query)
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
    browser_execute_script(session, @js_trigger_blur, [css_selector])
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
    browser_assert_text(session, text)
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Private Helpers
  # ─────────────────────────────────────────────────────────────────────────

  defp eval_js(session, script, args \\ []) do
    ref = make_ref()
    pid = self()

    browser_execute_script(session, script, args, fn result ->
      send(pid, {ref, result})
    end)

    receive do
      {^ref, result} -> result
    after
      5_000 -> raise "NbInertia.WallabyHelpers: JavaScript execution timed out"
    end
  end

  defp ensure_inertia_state_tracker(session) do
    browser_execute_script(session, @js_install_state_tracker, [])
    session
  end

  defp browser_visit(session, path), do: apply(browser_module(), :visit, [session, path])
  defp browser_has?(session, query), do: apply(browser_module(), :has?, [session, query])

  defp browser_has_no_css?(session, css),
    do: apply(browser_module(), :has_no_css?, [session, css])

  defp browser_current_path(session), do: apply(browser_module(), :current_path, [session])
  defp browser_click(session, query), do: apply(browser_module(), :click, [session, query])

  defp browser_accept_confirm(session, fun),
    do: apply(browser_module(), :accept_confirm, [session, fun])

  defp browser_send_keys(session, keys), do: apply(browser_module(), :send_keys, [session, keys])

  defp browser_send_keys(session, query, keys),
    do: apply(browser_module(), :send_keys, [session, query, keys])

  defp browser_find(session, query, callback),
    do: apply(browser_module(), :find, [session, query, callback])

  defp browser_assert_text(session, text),
    do: apply(browser_module(), :assert_text, [session, text])

  defp browser_fill_in(session, query, with: value),
    do: apply(browser_module(), :fill_in, [session, query, [with: value]])

  defp browser_execute_script(session, script, args),
    do: apply(browser_module(), :execute_script, [session, script, args])

  defp browser_execute_script(session, script, args, callback),
    do: apply(browser_module(), :execute_script, [session, script, args, callback])

  defp query_css(selector, opts \\ []), do: apply(query_module(), :css, [selector, opts])
  defp query_button(text), do: apply(query_module(), :button, [text])
  defp query_link(text), do: apply(query_module(), :link, [text])
  defp query_fillable_field(field), do: apply(query_module(), :fillable_field, [field])

  defp resolve_form_field_query(session, field) do
    fillable_query = query_fillable_field(field)

    if browser_has?(session, fillable_query) do
      {:fillable, fillable_query}
    else
      password_query =
        query_css(
          ~s(input[type="password"][id="#{field}"], input[type="password"][name="#{field}"])
        )

      if browser_has?(session, password_query) do
        {:password, field}
      else
        {:fillable, fillable_query}
      end
    end
  end

  defp password_field_name?(field), do: String.contains?(field, "password")

  defp wait_for_expected(fun, predicate) do
    deadline = System.monotonic_time(:millisecond) + @assertion_timeout
    wait_for_expected(fun, predicate, deadline)
  end

  defp wait_for_expected(fun, predicate, deadline) do
    value = fun.()

    cond do
      predicate.(value) ->
        value

      System.monotonic_time(:millisecond) >= deadline ->
        value

      true ->
        Process.sleep(@assertion_interval)
        wait_for_expected(fun, predicate, deadline)
    end
  end

  defp browser_module do
    ensure_wallaby_loaded!()
    Wallaby.Browser
  end

  defp query_module do
    ensure_wallaby_loaded!()
    Wallaby.Query
  end

  defp ensure_wallaby_loaded! do
    if Code.ensure_loaded?(Wallaby.Browser) and Code.ensure_loaded?(Wallaby.Query) do
      :ok
    else
      raise """
      NbInertia.WallabyHelpers requires Wallaby to be available.

      Add this to your test dependencies:

          {:wallaby, "~> 0.30", only: :test}
      """
    end
  end
end
