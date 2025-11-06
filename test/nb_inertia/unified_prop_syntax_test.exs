defmodule NbInertia.UnifiedPropSyntaxTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests for unified prop syntax matching the field syntax from NbSerializer.

  New unified syntax:
  - prop :tags, list: :string
  - prop :users, list: UserSerializer
  - prop :status, enum: ["active", "inactive"]
  - prop :roles, list: [enum: ["admin", "user"]]
  """

  describe "prop macro with unified syntax" do
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

    test "supports optional modifier with list: :string" do
      defmodule TestOptionalListController do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:tags, list: :string, optional: true)
        end
      end

      pages = TestOptionalListController.__inertia_pages__()
      props = pages[:test_page].props

      assert length(props) == 1
      [prop] = props

      assert prop.name == :tags
      assert Keyword.get(prop.opts, :list) == :string
      assert Keyword.get(prop.opts, :optional) == true
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

  # Note: TypeScript generation tests are in nb_ts/test/nb_ts/inertia_prop_generation_test.exs
  # since TypeScript generation is handled by nb_ts, not nb_inertia
end
