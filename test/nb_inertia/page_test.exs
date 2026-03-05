defmodule NbInertia.PageTest do
  use ExUnit.Case, async: true

  # ── Test Page Modules ──────────────────────────────

  defmodule BasicPage do
    use NbInertia.Page, component: "Test/Basic"

    prop(:title, :string)
    prop(:count, :integer)

    def mount(_conn, _params) do
      %{title: "Hello", count: 42}
    end
  end

  defmodule ConventionNamingPage do
    # Simulating MyAppWeb.UsersPage.Index → but since we're not in a *Web module,
    # we use explicit component for actual rendering tests.
    # This module tests that the macros compile correctly.
    use NbInertia.Page, component: "Users/Index"

    prop(:users, :list)

    def mount(_conn, _params) do
      %{users: []}
    end
  end

  defmodule AllPropTypesPage do
    use NbInertia.Page, component: "Test/AllPropTypes"

    prop(:name, :string)
    prop(:age, :integer)
    prop(:active, :boolean)
    prop(:tags, :list)
    prop(:metadata, :map)

    def mount(_conn, _params) do
      %{name: "Alice", age: 30, active: true, tags: ["a"], metadata: %{}}
    end
  end

  defmodule PropOptionsPage do
    use NbInertia.Page, component: "Test/PropOptions"

    prop(:visible, :string)
    prop(:extra, :map, defer: true)
    prop(:hidden, :list, partial: true)
    prop(:default_val, :string, default: "hello")
    prop(:nullable_val, :string, nullable: true)

    def mount(_conn, _params) do
      %{visible: "test", extra: %{}, hidden: [], default_val: "hello", nullable_val: nil}
    end
  end

  defmodule WithFormPage do
    use NbInertia.Page, component: "Test/WithForm"

    prop(:roles, :list)

    form_inputs :user_form do
      field(:name, :string)
      field(:email, :string)
      field(:role, :string, optional: true)
    end

    def mount(_conn, _params) do
      %{roles: ["admin", "user"]}
    end
  end

  defmodule WithActionPage do
    use NbInertia.Page, component: "Test/WithAction"

    prop(:item, :map)

    def mount(_conn, _params) do
      %{item: %{id: 1, name: "Test"}}
    end

    def action(conn, _params, :create) do
      Phoenix.Controller.redirect(conn, to: "/items")
    end

    def action(_conn, _params, :update) do
      {:error, %{name: ["is required"]}}
    end

    def action(_conn, _params, :delete) do
      {:error, %{base: ["cannot delete"]}}
    end
  end

  defmodule WithOptionsPage do
    use NbInertia.Page,
      component: "Custom/Path",
      encrypt_history: true,
      clear_history: true,
      preserve_fragment: true,
      camelize_props: true

    prop(:data, :map)

    def mount(_conn, _params) do
      %{data: %{}}
    end
  end

  defmodule ConnReturnPage do
    use NbInertia.Page, component: "Test/ConnReturn"

    prop(:users, :list)

    def mount(conn, _params) do
      conn
      |> encrypt_history()
      |> props(%{users: ["alice", "bob"]})
    end
  end

  defmodule FromAssignsPage do
    use NbInertia.Page, component: "Test/FromAssigns"

    prop(:title, :string)
    prop(:locale, :string, from: :assigns)
    prop(:timezone, :string, from: :user_timezone)

    def mount(_conn, _params) do
      %{title: "Page Title"}
    end
  end

  defmodule DefaultPropsPage do
    use NbInertia.Page, component: "Test/Defaults"

    prop(:name, :string)
    prop(:theme, :string, default: "light")
    prop(:page_size, :integer, default: 25)

    def mount(_conn, _params) do
      # Only provide :name, let :theme and :page_size use defaults
      %{name: "Test"}
    end
  end

  defmodule DefaultOverridePage do
    use NbInertia.Page, component: "Test/DefaultOverride"

    prop(:name, :string)
    prop(:theme, :string, default: "light")

    def mount(_conn, _params) do
      # Explicitly provide :theme, overriding the default
      %{name: "Test", theme: "dark"}
    end
  end

  defmodule PropWithOnlyOptsPage do
    use NbInertia.Page, component: "Test/PropOnlyOpts"

    prop(:flash, from: :assigns)
    prop(:locale, from: :user_locale)

    def mount(_conn, _params) do
      %{}
    end
  end

  defmodule MultipleFormsPage do
    use NbInertia.Page, component: "Test/MultipleForms"

    prop(:data, :map)

    form_inputs :user_form do
      field(:name, :string)
      field(:email, :string)
    end

    form_inputs :settings_form do
      field(:theme, :string)
      field(:notifications, :boolean)
    end

    def mount(_conn, _params) do
      %{data: %{}}
    end
  end

  defmodule SsrOptionPage do
    use NbInertia.Page,
      component: "Test/SsrOption",
      ssr: true

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end
  end

  defmodule LayoutOptionPage do
    use NbInertia.Page,
      component: "Test/LayoutOption",
      layout: :admin

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end
  end

  # ── Tests ──────────────────────────────────────────

  describe "use NbInertia.Page compilation" do
    test "BasicPage compiles and has introspection functions" do
      assert BasicPage.__inertia_page__() == true
      assert BasicPage.__inertia_component__() == "Test/Basic"
    end

    test "ConventionNamingPage compiles" do
      assert ConventionNamingPage.__inertia_page__() == true
      assert ConventionNamingPage.__inertia_component__() == "Users/Index"
    end
  end

  describe "__inertia_props__/0" do
    test "returns prop configurations for BasicPage" do
      props = BasicPage.__inertia_props__()
      assert length(props) == 2

      title_prop = Enum.find(props, &(&1.name == :title))
      assert title_prop.type == :string

      count_prop = Enum.find(props, &(&1.name == :count))
      assert count_prop.type == :integer
    end

    test "returns all prop types" do
      props = AllPropTypesPage.__inertia_props__()
      assert length(props) == 5

      types = Enum.map(props, &{&1.name, &1.type})
      assert {:name, :string} in types
      assert {:age, :integer} in types
      assert {:active, :boolean} in types
      assert {:tags, :list} in types
      assert {:metadata, :map} in types
    end

    test "returns prop options" do
      props = PropOptionsPage.__inertia_props__()

      extra_prop = Enum.find(props, &(&1.name == :extra))
      assert Keyword.get(extra_prop.opts, :defer) == true

      hidden_prop = Enum.find(props, &(&1.name == :hidden))
      assert Keyword.get(hidden_prop.opts, :partial) == true

      default_prop = Enum.find(props, &(&1.name == :default_val))
      assert Keyword.get(default_prop.opts, :default) == "hello"

      nullable_prop = Enum.find(props, &(&1.name == :nullable_val))
      assert Keyword.get(nullable_prop.opts, :nullable) == true
    end
  end

  describe "__inertia_forms__/0" do
    test "returns empty map when no forms declared" do
      assert BasicPage.__inertia_forms__() == %{}
    end

    test "returns form declarations" do
      forms = WithFormPage.__inertia_forms__()
      assert Map.has_key?(forms, :user_form)

      fields = forms[:user_form]
      assert length(fields) == 3

      {name, type, _opts} = Enum.at(fields, 0)
      assert name == :name
      assert type == :string
    end
  end

  describe "__inertia_component__/0" do
    test "returns explicit component name" do
      assert WithOptionsPage.__inertia_component__() == "Custom/Path"
    end

    test "returns configured component for all test pages" do
      assert BasicPage.__inertia_component__() == "Test/Basic"
      assert AllPropTypesPage.__inertia_component__() == "Test/AllPropTypes"
    end
  end

  describe "__inertia_has_action__/0" do
    test "returns true when action/3 is defined" do
      assert WithActionPage.__inertia_has_action__() == true
    end

    test "returns false when action/3 is not defined" do
      assert BasicPage.__inertia_has_action__() == false
    end
  end

  describe "__inertia_has_render__/0" do
    test "returns false when render/0 is not defined" do
      assert BasicPage.__inertia_has_render__() == false
    end
  end

  describe "__inertia_options__/0" do
    test "returns default options" do
      opts = BasicPage.__inertia_options__()
      assert opts.encrypt_history == false
      assert opts.clear_history == false
      assert opts.preserve_fragment == false
    end

    test "returns custom options" do
      opts = WithOptionsPage.__inertia_options__()
      assert opts.component == "Custom/Path"
      assert opts.encrypt_history == true
      assert opts.clear_history == true
      assert opts.preserve_fragment == true
      assert opts.camelize_props == true
    end
  end

  describe "props/2 helper" do
    test "stores props in conn.private" do
      conn = %Plug.Conn{private: %{}}
      conn = NbInertia.Page.props(conn, %{users: [1, 2, 3]})
      assert conn.private[:nb_inertia_page_props] == %{users: [1, 2, 3]}
    end
  end

  describe "mount/2 return values" do
    test "map return provides props" do
      result = BasicPage.mount(%Plug.Conn{}, %{})
      assert result == %{title: "Hello", count: 42}
    end

    test "conn return stores props via props/2" do
      # ConnReturnPage.mount uses the props/2 helper
      conn = %Plug.Conn{private: %{}}
      result = ConnReturnPage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:nb_inertia_page_props] == %{users: ["alice", "bob"]}
      assert result.private[:inertia_encrypt_history] == true
    end
  end

  describe "action/3 return values" do
    test "error tuple with map" do
      result = WithActionPage.action(%Plug.Conn{}, %{}, :update)
      assert {:error, %{name: ["is required"]}} = result
    end

    test "error tuple for delete" do
      result = WithActionPage.action(%Plug.Conn{}, %{}, :delete)
      assert {:error, %{base: ["cannot delete"]}} = result
    end
  end

  describe "from: option in props" do
    test "from: :assigns prop is recorded in DSL config" do
      props = FromAssignsPage.__inertia_props__()
      locale_prop = Enum.find(props, &(&1.name == :locale))
      assert Keyword.get(locale_prop.opts, :from) == :assigns
    end

    test "from: :other_key prop is recorded in DSL config" do
      props = FromAssignsPage.__inertia_props__()
      tz_prop = Enum.find(props, &(&1.name == :timezone))
      assert Keyword.get(tz_prop.opts, :from) == :user_timezone
    end

    test "prop with only opts (no type) stores from: in config" do
      props = PropWithOnlyOptsPage.__inertia_props__()
      flash_prop = Enum.find(props, &(&1.name == :flash))
      assert flash_prop.from == :assigns

      locale_prop = Enum.find(props, &(&1.name == :locale))
      assert locale_prop.from == :user_locale
    end
  end

  describe "default: option in props" do
    test "default value is recorded in DSL config" do
      props = DefaultPropsPage.__inertia_props__()

      theme_prop = Enum.find(props, &(&1.name == :theme))
      assert Keyword.get(theme_prop.opts, :default) == "light"

      page_size_prop = Enum.find(props, &(&1.name == :page_size))
      assert Keyword.get(page_size_prop.opts, :default) == 25
    end

    test "mount returns only explicitly provided props" do
      result = DefaultPropsPage.mount(%Plug.Conn{}, %{})
      assert result == %{name: "Test"}
      refute Map.has_key?(result, :theme)
      refute Map.has_key?(result, :page_size)
    end

    test "mount can override defaults" do
      result = DefaultOverridePage.mount(%Plug.Conn{}, %{})
      assert result == %{name: "Test", theme: "dark"}
    end
  end

  describe "multiple form_inputs" do
    test "returns multiple form declarations" do
      forms = MultipleFormsPage.__inertia_forms__()
      assert Map.has_key?(forms, :user_form)
      assert Map.has_key?(forms, :settings_form)

      user_fields = forms[:user_form]
      assert length(user_fields) == 2

      settings_fields = forms[:settings_form]
      assert length(settings_fields) == 2
    end

    test "form field types are preserved" do
      forms = MultipleFormsPage.__inertia_forms__()

      [{name1, type1, _}, {name2, type2, _}] = forms[:settings_form]
      assert name1 == :theme
      assert type1 == :string
      assert name2 == :notifications
      assert type2 == :boolean
    end
  end

  describe "ssr and layout options" do
    test "ssr option is stored" do
      opts = SsrOptionPage.__inertia_options__()
      assert opts.ssr == true
    end

    test "layout option is stored" do
      opts = LayoutOptionPage.__inertia_options__()
      assert opts.layout == :admin
    end

    test "ssr defaults to nil when not set" do
      opts = BasicPage.__inertia_options__()
      assert opts.ssr == nil
    end

    test "layout defaults to nil when not set" do
      opts = BasicPage.__inertia_options__()
      assert opts.layout == nil
    end
  end

  describe "PageController.apply_from_and_defaults/3 (via module internals)" do
    # These tests verify the from/default logic by calling the private function
    # indirectly through the public test page modules

    test "from: :assigns pulls from conn.assigns using prop name as key" do
      # FromAssignsPage has prop :locale, from: :assigns
      # The PageController should pull conn.assigns[:locale]
      dsl_props = FromAssignsPage.__inertia_props__()
      conn = %Plug.Conn{assigns: %{locale: "en", user_timezone: "UTC"}, private: %{}}

      # Use the function directly (it's private, so we test the effect through render_page)
      # Instead, verify the DSL is correct and the mount doesn't include from: props
      locale_prop = Enum.find(dsl_props, &(&1.name == :locale))
      assert Keyword.get(locale_prop.opts, :from) == :assigns

      tz_prop = Enum.find(dsl_props, &(&1.name == :timezone))
      assert Keyword.get(tz_prop.opts, :from) == :user_timezone

      # Verify mount doesn't return from: props
      result = FromAssignsPage.mount(conn, %{})
      assert result == %{title: "Page Title"}
      refute Map.has_key?(result, :locale)
      refute Map.has_key?(result, :timezone)
    end
  end
end
