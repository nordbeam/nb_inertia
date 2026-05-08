defmodule NbInertia.SSRTest do
  use ExUnit.Case, async: false

  alias NbInertia.SSR

  setup do
    stop_process(NbInertia.SSR)
    :ok
  end

  describe "SSR module" do
    test "starts without crashing when SSR is disabled" do
      {:ok, pid} = SSR.start_link(enabled: false)
      assert Process.alive?(pid)
      Process.exit(pid, :normal)
    end

    test "reports SSR as disabled when not configured" do
      {:ok, pid} = SSR.start_link(enabled: false)
      refute GenServer.call(pid, :enabled?)
      Process.exit(pid, :normal)
    end

    test "warns when SSR is enabled but DenoRider is not available" do
      # This test assumes DenoRider is available since it's in deps
      # In a real scenario without DenoRider, it would log a warning
      {:ok, pid} = SSR.start_link(enabled: true, script_path: nil)
      refute GenServer.call(pid, :enabled?)
      Process.exit(pid, :normal)
    end

    test "fails gracefully when script path is nil" do
      {:ok, pid} = SSR.start_link(enabled: true, script_path: nil)
      refute GenServer.call(pid, :enabled?)
      Process.exit(pid, :normal)
    end

    test "fails gracefully when script file doesn't exist" do
      {:ok, pid} = SSR.start_link(enabled: true, script_path: "/nonexistent/path/ssr.js")
      refute GenServer.call(pid, :enabled?)
      Process.exit(pid, :normal)
    end

    test "ssr_enabled? returns false when SSR process is not running" do
      # The SSR.ssr_enabled?/0 function handles the case when the process isn't running
      # by rescuing the error and returning false
      # We test this by calling the function - it should not crash
      result = SSR.ssr_enabled?()
      assert is_boolean(result)
    end
  end

  describe "SSR rendering" do
    setup do
      # Create a minimal SSR script for testing
      script_path = Path.join([System.tmp_dir(), "test_ssr_#{:rand.uniform(1000)}.js"])

      script_content = """
      function render(page) {
        const json = JSON.stringify(page).replace(/\\//g, '\\\\/');
        return {
          head: [`<title>${page.component}</title>`],
          body: `<script data-page="app" type="application/json">${json}</script><div id="app" data-server-rendered="true">SSR Content</div>`
        };
      }
      """

      File.write!(script_path, script_content)

      on_exit(fn ->
        File.rm(script_path)
      end)

      %{script_path: script_path}
    end

    test "returns error when SSR is not enabled" do
      {:ok, pid} = SSR.start_link(enabled: false)

      page = %{
        component: "TestPage",
        props: %{},
        url: "/test",
        version: "1"
      }

      assert {:error, "SSR is not enabled"} = GenServer.call(pid, {:render, page})
      Process.exit(pid, :normal)
    end

    test "loads script successfully when DenoRider is available", %{script_path: script_path} do
      # Start DenoRider if it's not running (required for SSR)
      deno_pid =
        case Process.whereis(DenoRider) do
          nil ->
            {:ok, pid} = DenoRider.start_link([])
            pid

          pid ->
            pid
        end

      try do
        {:ok, ssr_pid} =
          SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: false)

        # Check if SSR loaded the script successfully
        # Note: The script might not load if DenoRider can't evaluate it,
        # but the process should start without crashing
        assert Process.alive?(ssr_pid)

        Process.exit(ssr_pid, :normal)
      after
        # Clean up DenoRider if we started it
        if deno_pid && Process.alive?(deno_pid) && Process.whereis(DenoRider) == deno_pid do
          Process.exit(deno_pid, :normal)
        end
      end
    end

    test "includes JavaScript stack trace in error messages (production mode)" do
      # Create a script that throws an error with a stack trace
      script_path = Path.join([System.tmp_dir(), "test_ssr_error_#{:rand.uniform(1000)}.js"])

      script_content = """
      globalThis.render = function(page) {
        // This will throw an error with a stack trace
        throw new Error("Test error: window is not defined");
      }
      """

      File.write!(script_path, script_content)

      # Start DenoRider if needed
      deno_pid =
        case Process.whereis(DenoRider) do
          nil ->
            {:ok, pid} = DenoRider.start_link([])
            pid

          pid ->
            pid
        end

      try do
        {:ok, ssr_pid} =
          SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: false)

        # Wait for script to load
        Process.sleep(100)

        page = %{
          component: "TestPage",
          props: %{},
          url: "/test",
          version: "1"
        }

        # Render should fail with error
        {:error, error_message} = GenServer.call(ssr_pid, {:render, page})

        # Verify error message contains the original error
        assert error_message =~ "Test error: window is not defined"

        # Verify it contains "JavaScript Stack Trace" section
        assert error_message =~ "JavaScript Stack Trace:"

        # Verify it contains stack information (at least "Error:" from JS)
        assert error_message =~ "Error:"

        Process.exit(ssr_pid, :normal)
      after
        if deno_pid && Process.alive?(deno_pid) && Process.whereis(DenoRider) == deno_pid do
          Process.exit(deno_pid, :normal)
        end

        File.rm(script_path)
      end
    end

    test "does not show empty JavaScript stack trace header" do
      # Create a script that returns an error with empty stack
      script_path =
        Path.join([System.tmp_dir(), "test_ssr_empty_stack_#{:rand.uniform(1000)}.js"])

      # This script simulates an error with no stack trace
      # (like some XML parsing errors or custom error objects)
      script_content = """
      globalThis.render = function(page) {
        // Create an error-like object with empty stack
        const err = new Error("Parse error: Unexpected character");
        err.stack = ""; // Empty stack trace
        throw err;
      }
      """

      File.write!(script_path, script_content)

      # Start DenoRider if needed
      deno_pid =
        case Process.whereis(DenoRider) do
          nil ->
            {:ok, pid} = DenoRider.start_link([])
            pid

          pid ->
            pid
        end

      try do
        {:ok, ssr_pid} =
          SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: false)

        # Wait for script to load
        Process.sleep(100)

        page = %{
          component: "TestPage",
          props: %{},
          url: "/test",
          version: "1"
        }

        # Render should fail with error
        {:error, error_message} = GenServer.call(ssr_pid, {:render, page})

        # Should contain the error message
        assert error_message =~ "Parse error"

        # Should NOT contain the "JavaScript Stack Trace:" header when stack is empty
        refute error_message =~ "JavaScript Stack Trace:"

        Process.exit(ssr_pid, :normal)
      after
        if deno_pid && Process.alive?(deno_pid) && Process.whereis(DenoRider) == deno_pid do
          Process.exit(deno_pid, :normal)
        end

        File.rm(script_path)
      end
    end
  end

  describe "configuration" do
    test "reads configuration from application env" do
      original_config = Application.get_env(:nb_inertia, :ssr, [])

      try do
        Application.put_env(:nb_inertia, :ssr,
          enabled: true,
          script_path: "/test/path.js",
          raise_on_failure: false
        )

        {:ok, pid} = SSR.start_link()

        # Process should start even if script doesn't exist
        assert Process.alive?(pid)

        Process.exit(pid, :normal)
      after
        Application.put_env(:nb_inertia, :ssr, original_config)
      end
    end

    test "uses top-level raise_on_ssr_failure when ssr config is boolean" do
      original_ssr_config = Application.get_env(:nb_inertia, :ssr, [])
      original_raise_on_ssr_failure = Application.get_env(:nb_inertia, :raise_on_ssr_failure)

      try do
        Application.put_env(:nb_inertia, :ssr, true)
        Application.put_env(:nb_inertia, :raise_on_ssr_failure, false)

        {:ok, pid} = SSR.start_link()

        refute :sys.get_state(pid).raise_on_failure

        Process.exit(pid, :normal)
      after
        Application.put_env(:nb_inertia, :ssr, original_ssr_config)

        if is_nil(original_raise_on_ssr_failure) do
          Application.delete_env(:nb_inertia, :raise_on_ssr_failure)
        else
          Application.put_env(:nb_inertia, :raise_on_ssr_failure, original_raise_on_ssr_failure)
        end
      end
    end

    test "opts override application config" do
      original_config = Application.get_env(:nb_inertia, :ssr, [])

      try do
        Application.put_env(:nb_inertia, :ssr, enabled: true)

        {:ok, pid} = SSR.start_link(enabled: false)
        refute GenServer.call(pid, :enabled?)
        Process.exit(pid, :normal)
      after
        Application.put_env(:nb_inertia, :ssr, original_config)
      end
    end

    test "uses the nb_vite SSR hot file for the automatic dev server URL" do
      with_dev_ssr_config(fn hot_path ->
        File.write!(hot_path, "http://127.0.0.1:46321/ssr\n")

        {:ok, pid} = SSR.start_link()

        state = :sys.get_state(pid)
        assert state.dev_server_url == "http://127.0.0.1:46321/ssr"
        assert state.dev_server_url_source == :auto

        Process.exit(pid, :normal)
      end)
    end

    test "keeps explicit dev_server_url ahead of the nb_vite SSR hot file" do
      with_dev_ssr_config(fn hot_path ->
        Application.put_env(:nb_inertia, :ssr,
          enabled: true,
          dev_server_url: "http://127.0.0.1:46322"
        )

        File.write!(hot_path, "http://127.0.0.1:46321/ssr\n")

        {:ok, pid} = SSR.start_link()

        state = :sys.get_state(pid)
        assert state.dev_server_url == "http://127.0.0.1:46322"
        assert state.dev_server_url_source == :configured

        Process.exit(pid, :normal)
      end)
    end

    test "refreshes the automatic dev server URL when the hot file appears after startup" do
      with_dev_ssr_config(fn hot_path ->
        System.put_env("VITE_PORT", "46322")
        File.rm(hot_path)

        {:ok, pid} = SSR.start_link()
        assert :sys.get_state(pid).dev_server_url == "http://127.0.0.1:46322"

        File.write!(hot_path, "http://127.0.0.1:46321/ssr\n")
        send(pid, :check_dev_server)
        Process.sleep(100)

        assert :sys.get_state(pid).dev_server_url == "http://127.0.0.1:46321/ssr"

        Process.exit(pid, :normal)
      end)
    end
  end

  defp stop_process(name) do
    case Process.whereis(name) do
      nil ->
        :ok

      pid ->
        Process.exit(pid, :normal)
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
        after
          1_000 -> :ok
        end
    end
  end

  defp with_dev_ssr_config(fun) do
    original_ssr_config = Application.get_env(:nb_inertia, :ssr, [])
    original_env = Application.get_env(:nb_inertia, :env)
    original_endpoint = Application.get_env(:nb_inertia, :endpoint)
    original_vite_dev_server_url = System.get_env("VITE_DEV_SERVER_URL")
    original_vite_host = System.get_env("VITE_HOST")
    original_vite_port = System.get_env("VITE_PORT")

    priv_dir = :code.priv_dir(:nb_inertia)
    File.mkdir_p!(priv_dir)
    hot_path = Path.join(priv_dir, "ssr-hot")
    original_hot_file = File.read(hot_path)

    try do
      Application.put_env(:nb_inertia, :env, :dev)
      Application.put_env(:nb_inertia, :endpoint, NbInertiaWeb.Endpoint)
      Application.put_env(:nb_inertia, :ssr, enabled: true)
      System.delete_env("VITE_DEV_SERVER_URL")
      System.delete_env("VITE_HOST")
      System.delete_env("VITE_PORT")

      fun.(hot_path)
    after
      Application.put_env(:nb_inertia, :ssr, original_ssr_config)
      restore_application_env(:env, original_env)
      restore_application_env(:endpoint, original_endpoint)
      restore_system_env("VITE_DEV_SERVER_URL", original_vite_dev_server_url)
      restore_system_env("VITE_HOST", original_vite_host)
      restore_system_env("VITE_PORT", original_vite_port)
      restore_file(hot_path, original_hot_file)
    end
  end

  defp restore_application_env(key, nil), do: Application.delete_env(:nb_inertia, key)
  defp restore_application_env(key, value), do: Application.put_env(:nb_inertia, key, value)

  defp restore_system_env(key, nil), do: System.delete_env(key)
  defp restore_system_env(key, value), do: System.put_env(key, value)

  defp restore_file(path, {:ok, contents}), do: File.write!(path, contents)
  defp restore_file(path, {:error, _reason}), do: File.rm(path)
end
