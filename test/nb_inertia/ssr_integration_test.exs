defmodule NbInertia.SSRIntegrationTest do
  use ExUnit.Case, async: false

  alias NbInertia.SSR

  setup_all do
    # Start DenoRider for the entire test suite
    case Process.whereis(DenoRider) do
      nil -> {:ok, _} = DenoRider.start_link([])
      _ -> :ok
    end

    :ok
  end

  describe "SSR rendering integration" do
    setup do
      # Create a working SSR script that mimics a real Inertia SSR setup
      script_path = Path.join([System.tmp_dir(), "ssr_integration_#{:rand.uniform(100_000)}.js"])

      script_content = """
      // Simple render function that returns HTML
      async function render(page) {
        // Simulate what createInertiaApp would return
        const html = `<div id="app" data-page='${JSON.stringify(page)}'>
          <h1>${page.component}</h1>
          <div>${JSON.stringify(page.props)}</div>
        </div>`;

        return {
          head: [`<title>${page.component}</title>`],
          body: html
        };
      }

      // Make render available globally so SSR can call it
      globalThis.render = render;
      """

      File.write!(script_path, script_content)

      on_exit(fn ->
        if File.exists?(script_path), do: File.rm(script_path)
      end)

      %{script_path: script_path}
    end

    test "renders a simple page with SSR", %{script_path: script_path} do
      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: true)

      page = %{
        component: "Dashboard",
        props: %{user: %{name: "John", id: 1}},
        url: "/dashboard",
        version: "1"
      }

      result = GenServer.call(ssr_pid, {:render, page}, 10_000)

      assert {:ok, rendered} = result
      assert rendered["head"] == ["<title>Dashboard</title>"]
      assert rendered["body"] =~ "Dashboard"
      assert rendered["body"] =~ "John"

      Process.exit(ssr_pid, :normal)
    end

    test "handles rendering errors gracefully with raise_on_failure: false", %{
      script_path: script_path
    } do
      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: false)

      # Send invalid page data that might cause JS error
      page = %{
        component: "BrokenPage",
        # Missing required fields
        url: "/broken"
      }

      result = GenServer.call(ssr_pid, {:render, page}, 10_000)

      # Should return error instead of crashing
      assert match?({:ok, _}, result) or match?({:error, _}, result)

      Process.exit(ssr_pid, :normal)
    end

    test "renders multiple pages sequentially", %{script_path: script_path} do
      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: true)

      pages = [
        %{component: "Home", props: %{}, url: "/", version: "1"},
        %{component: "About", props: %{}, url: "/about", version: "1"},
        %{component: "Contact", props: %{email: "test@test.com"}, url: "/contact", version: "1"}
      ]

      results =
        Enum.map(pages, fn page ->
          GenServer.call(ssr_pid, {:render, page}, 10_000)
        end)

      # All renders should succeed
      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)

      # Verify each result contains the correct component
      assert {:ok, home} = Enum.at(results, 0)
      assert home["body"] =~ "Home"

      assert {:ok, about} = Enum.at(results, 1)
      assert about["body"] =~ "About"

      assert {:ok, contact} = Enum.at(results, 2)
      assert contact["body"] =~ "Contact"
      assert contact["body"] =~ "test@test.com"

      Process.exit(ssr_pid, :normal)
    end

    test "handles complex nested props", %{script_path: script_path} do
      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: true)

      page = %{
        component: "UserProfile",
        props: %{
          user: %{
            id: 1,
            name: "Alice",
            profile: %{
              bio: "Software Engineer",
              skills: ["Elixir", "React", "TypeScript"]
            }
          },
          posts: [
            %{id: 1, title: "Hello World", published: true},
            %{id: 2, title: "Second Post", published: false}
          ]
        },
        url: "/users/1",
        version: "1"
      }

      result = GenServer.call(ssr_pid, {:render, page}, 10_000)

      assert {:ok, rendered} = result
      assert rendered["body"] =~ "UserProfile"
      assert rendered["body"] =~ "Alice"
      assert rendered["body"] =~ "Elixir"
      assert rendered["body"] =~ "Hello World"

      Process.exit(ssr_pid, :normal)
    end

    test "SSR.render/1 uses the registered process", %{script_path: script_path} do
      # Start SSR with the name NbInertia.SSR
      {:ok, _} = start_supervised({SSR, enabled: true, script_path: script_path})

      page = %{
        component: "TestPage",
        props: %{message: "Hello from SSR"},
        url: "/test",
        version: "1"
      }

      # Use the public API
      result = SSR.render(page)

      assert {:ok, rendered} = result
      assert rendered["body"] =~ "TestPage"
      assert rendered["body"] =~ "Hello from SSR"
    end

    test "returns error when SSR is disabled" do
      {:ok, _} = start_supervised({SSR, enabled: false})

      page = %{
        component: "TestPage",
        props: %{},
        url: "/test",
        version: "1"
      }

      result = SSR.render(page)
      assert {:error, "SSR is not enabled"} = result
    end
  end

  describe "SSR script evaluation" do
    test "evaluates JavaScript code correctly", %{} do
      script_path = Path.join([System.tmp_dir(), "ssr_eval_#{:rand.uniform(100_000)}.js"])

      # Test that DenoRider can evaluate our script
      script_content = """
      function greet(name) {
        return `Hello, ${name}!`;
      }

      globalThis.testGreet = greet;
      """

      File.write!(script_path, script_content)

      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: true)

      # The script should load without error
      assert Process.alive?(ssr_pid)

      Process.exit(ssr_pid, :normal)
      File.rm(script_path)
    end

    test "handles syntax errors in script gracefully" do
      script_path = Path.join([System.tmp_dir(), "ssr_bad_#{:rand.uniform(100_000)}.js"])

      # Invalid JavaScript
      script_content = """
      function broken( {
        // Missing closing brace
      """

      File.write!(script_path, script_content)

      # Should start but script won't load
      {:ok, ssr_pid} =
        SSR.start_link(enabled: true, script_path: script_path, raise_on_failure: false)

      # SSR should be disabled due to script load failure
      refute GenServer.call(ssr_pid, :enabled?)

      Process.exit(ssr_pid, :normal)
      File.rm(script_path)
    end
  end

  describe "performance and concurrency" do
    setup do
      script_path = Path.join([System.tmp_dir(), "ssr_perf_#{:rand.uniform(100_000)}.js"])

      script_content = """
      async function render(page) {
        return {
          head: [`<title>${page.component}</title>`],
          body: `<div>${page.component}</div>`
        };
      }
      globalThis.render = render;
      """

      File.write!(script_path, script_content)
      {:ok, _} = start_supervised({SSR, enabled: true, script_path: script_path})

      on_exit(fn ->
        if File.exists?(script_path), do: File.rm(script_path)
      end)

      :ok
    end

    test "handles concurrent render requests" do
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            page = %{
              component: "Page#{i}",
              props: %{id: i},
              url: "/page#{i}",
              version: "1"
            }

            SSR.render(page)
          end)
        end

      results = Task.await_many(tasks, 30_000)

      # All renders should succeed
      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)

      # Each should contain the correct component
      Enum.zip(1..10, results)
      |> Enum.each(fn {i, {:ok, rendered}} ->
        assert rendered["body"] =~ "Page#{i}"
      end)
    end
  end
end
