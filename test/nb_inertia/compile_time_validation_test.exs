defmodule NbInertia.CompileTimeValidationTest do
  @moduledoc """
  Tests that compile-time validation in nb_inertia actually raises CompileError
  when there are prop validation issues.
  """
  use ExUnit.Case, async: true

  describe "missing required props" do
    test "raises CompileError when required props are missing" do
      code = """
      defmodule TestMissingProps do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :total_count, :integer
        end

        def index(conn, _params) do
          # Missing both required props - provide at least one to trigger validation
          render_inertia(conn, :users_index, [users: []])
        end
      end
      """

      # The error message starts with file:line prefix
      assert_raise CompileError, ~r/Missing required props for Inertia page :users_index/s, fn ->
        Code.compile_string(code)
      end
    end

    test "raises CompileError when some required props are missing" do
      code = """
      defmodule TestPartiallyMissingProps do
        use NbInertia.Controller

        inertia_page :users_show do
          prop :user, :map
          prop :permissions, :list
        end

        def show(conn, _params) do
          # Only providing one of two required props
          render_inertia(conn, :users_show, [user: %{}])
        end
      end
      """

      # Use /s flag to make . match newlines
      assert_raise CompileError, ~r/Missing required props.*:permissions/s, fn ->
        Code.compile_string(code)
      end
    end

    test "does not raise when all required props are provided" do
      code = """
      defmodule TestAllPropsProvided do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :total_count, :integer
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, [users: [], total_count: 0])
        end
      end
      """

      # Should not raise
      Code.compile_string(code)
    end
  end

  describe "partial props" do
    test "does not raise when partial props are missing" do
      code = """
      defmodule TestPartialPropsMissing do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :filters, :map, partial: true
        end

        def index(conn, _params) do
          # Only providing required prop, skipping partial
          render_inertia(conn, :users_index, [users: []])
        end
      end
      """

      # Should not raise - partial props are not required
      Code.compile_string(code)
    end

    test "does not raise when lazy props are missing" do
      code = """
      defmodule TestLazyPropsMissing do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :stats, :map, lazy: true
        end

        def index(conn, _params) do
          # Lazy props don't need to be provided at render time
          render_inertia(conn, :users_index, [users: []])
        end
      end
      """

      # Should not raise - lazy props are not required at render time
      Code.compile_string(code)
    end

    test "does not raise when defer props are missing" do
      code = """
      defmodule TestDeferPropsMissing do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :recommendations, :list, defer: true
        end

        def index(conn, _params) do
          # Defer props don't need to be provided at render time
          render_inertia(conn, :users_index, [users: []])
        end
      end
      """

      # Should not raise - defer props are not required at render time
      Code.compile_string(code)
    end
  end

  describe "undeclared props" do
    test "raises CompileError when undeclared props are provided" do
      code = """
      defmodule TestExtraProps do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          # Providing an extra prop that wasn't declared
          render_inertia(conn, :users_index, [users: [], extra_data: "oops"])
        end
      end
      """

      # Use /s flag to make . match newlines
      assert_raise CompileError, ~r/Undeclared props provided.*:extra_data/s, fn ->
        Code.compile_string(code)
      end
    end

    test "raises CompileError with multiple undeclared props" do
      code = """
      defmodule TestMultipleExtraProps do
        use NbInertia.Controller

        inertia_page :simple_page do
          prop :title, :string
        end

        def show(conn, _params) do
          render_inertia(conn, :simple_page, [title: "Hello", foo: 1, bar: 2])
        end
      end
      """

      # Use /s flag to make . match newlines
      assert_raise CompileError, ~r/Undeclared props provided/s, fn ->
        Code.compile_string(code)
      end
    end
  end

  describe "from: :assigns props" do
    test "does not raise when from: :assigns props are missing" do
      code = """
      defmodule TestFromAssignsProps do
        use NbInertia.Controller

        inertia_page :profile do
          prop :user, :map, from: :assigns
          prop :extra_data, :string
        end

        def show(conn, _params) do
          # :user comes from assigns automatically, only :extra_data needed
          render_inertia(conn, :profile, [extra_data: "test"])
        end
      end
      """

      # Should not raise - from: :assigns props are auto-populated
      Code.compile_string(code)
    end
  end

  describe "dynamic props (no compile-time validation)" do
    test "skips validation when props are a variable" do
      code = """
      defmodule TestDynamicProps do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          props = [users: [], extra: "this would fail if validated"]
          # Validation is skipped because props is a variable, not a literal list
          render_inertia(conn, :users_index, props)
        end
      end
      """

      # Should not raise - dynamic props skip compile-time validation
      Code.compile_string(code)
    end

    test "skips validation when props is empty list" do
      code = """
      defmodule TestEmptyPropsAllowed do
        use NbInertia.Controller

        # Page with partial props only
        inertia_page :empty_page do
          prop :data, :any, partial: true
        end

        def show(conn, _params) do
          # Empty props should be allowed when all props are partial
          render_inertia(conn, :empty_page, [])
        end
      end
      """

      # Should not raise
      Code.compile_string(code)
    end
  end

  describe "prop collisions between shared and page props" do
    test "raises CompileError when shared prop collides with page prop" do
      code = """
      defmodule TestPropCollision do
        use NbInertia.Controller

        # Declare a shared prop
        inertia_shared do
          prop :current_user, :map, from: :assigns
        end

        inertia_page :users_index do
          prop :users, :list
          # This prop collides with the shared prop
          prop :current_user, :map
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, [users: [], current_user: %{}])
        end
      end
      """

      # Prop collision is detected during @before_compile
      assert_raise CompileError, ~r/Prop name collision.*:current_user/s, fn ->
        Code.compile_string(code)
      end
    end
  end

  describe "page not found" do
    test "does not raise at compile time for undeclared pages" do
      # Note: Page-not-found validation happens differently
      # The macro only validates props if the page config exists
      code = """
      defmodule TestUndeclaredPage do
        use NbInertia.Controller

        # No inertia_page declaration

        def show(conn, _params) do
          # This won't raise at compile-time because the page isn't registered
          # It will fail at runtime instead
          render_inertia(conn, :nonexistent_page, [foo: "bar"])
        end
      end
      """

      # Should not raise at compile-time
      # Runtime error would happen when trying to look up the component
      Code.compile_string(code)
    end
  end
end
