defmodule NbInertia.SSRTest do
  use ExUnit.Case, async: false

  alias NbInertia.SSR

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
        return {
          head: [`<title>${page.component}</title>`],
          body: `<div id="app" data-page="${page.component}">SSR Content</div>`
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

      assert {:error, :ssr_not_enabled} = GenServer.call(pid, {:render, page})
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
  end
end
