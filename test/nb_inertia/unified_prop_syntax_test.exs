defmodule NbInertia.UnifiedPropSyntaxTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests for native helper syntax plus keyword shorthand compatibility.
  """

  describe "prop macro keyword shorthand compatibility" do
    test "stores list: :string correctly" do
      defmodule TestListStringController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:tags, list: :string)
        end
      end

      pages = TestListStringController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :tags
      assert Keyword.get(prop.opts, :list) == :string
    end

    test "stores list: SerializerModule correctly" do
      defmodule TestUserSerializer do
        def __nb_serializer__, do: :ok
      end

      defmodule TestListSerializerController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:users, list: TestUserSerializer)
        end
      end

      pages = TestListSerializerController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :users
      assert Keyword.get(prop.opts, :list) == TestUserSerializer
    end

    test "stores enum: [...] correctly" do
      defmodule TestEnumController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:status, enum: ["active", "inactive", "pending"])
        end
      end

      pages = TestEnumController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :status
      assert Keyword.get(prop.opts, :enum) == ["active", "inactive", "pending"]
    end

    test "stores list: [enum: [...]] correctly" do
      defmodule TestListEnumController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:roles, list: [enum: ["admin", "user", "guest"]])
        end
      end

      pages = TestListEnumController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :roles
      list_value = Keyword.get(prop.opts, :list)
      assert is_list(list_value)
      assert Keyword.get(list_value, :enum) == ["admin", "user", "guest"]
    end

    test "supports partial modifier with list: :string" do
      defmodule TestPartialListController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:tags, list: :string, partial: true)
        end
      end

      pages = TestPartialListController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :tags
      assert Keyword.get(prop.opts, :list) == :string
      assert Keyword.get(prop.opts, :partial) == true
    end

    test "supports nullable modifier with enum" do
      defmodule TestNullableEnumController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:priority, enum: ["low", "high"], nullable: true)
        end
      end

      pages = TestNullableEnumController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :priority
      assert Keyword.get(prop.opts, :enum) == ["low", "high"]
      assert Keyword.get(prop.opts, :nullable) == true
    end
  end

  describe "prop macro native helper syntax" do
    test "stores explicit ref props as serializer-backed props" do
      defmodule TestExplicitRefController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:user, ref(TestUserSerializer))
        end
      end

      pages = TestExplicitRefController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :user
      assert prop.serializer == TestUserSerializer
    end

    test "stores native helper descriptors correctly" do
      defmodule TestNativeTypeHelpersController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:filters, shape(search: optional(:string), page: :integer))
          prop(:status, enum([:draft, :published]))
          prop(:settings, nullable(shape(theme: literal("dark"), compact: :boolean)))
          prop(:subject, union([ref(TestUserSerializer), ref(TestTeamSerializer)]))
          prop(:reviewers, list_of(ref(TestUserSerializer)))
        end
      end

      pages = TestNativeTypeHelpersController.__inertia_pages__()
      props = pages[:test_page].props

      assert Enum.find(props, &(&1.name == :filters)).type ==
               {:shape, [search: {:optional, :string}, page: :integer]}

      assert Enum.find(props, &(&1.name == :status)).type == {:enum, [:draft, :published]}

      assert Enum.find(props, &(&1.name == :settings)).type ==
               {:nullable, {:shape, [theme: {:literal, "dark"}, compact: :boolean]}}

      assert Enum.find(props, &(&1.name == :subject)).type ==
               {:union, [{:ref, TestUserSerializer}, {:ref, TestTeamSerializer}]}

      assert Enum.find(props, &(&1.name == :reviewers)).type ==
               {:list, {:ref, TestUserSerializer}}
    end

    test "rejects optional helper at the top level" do
      code = """
      defmodule TestInvalidOptionalTypeController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop :filters, optional(:string)
        end
      end
      """

      assert_raise ArgumentError,
                   ~r/optional\/1 is only valid inside shape\/1 field definitions/,
                   fn ->
                     Code.compile_string(code)
                   end
    end
  end

  # Note: TypeScript generation tests are in nb_ts/test/nb_ts/inertia_prop_generation_test.exs
  # since TypeScript generation is handled by nb_ts, not nb_inertia
end
