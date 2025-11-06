defmodule NbInertia.FormInputsTsIntegrationTest do
  @moduledoc """
  Integration test verifying that form_inputs from nb_inertia
  can be consumed by nb_ts for TypeScript generation.
  """
  use ExUnit.Case, async: true

  describe "nb_inertia → nb_ts integration" do
    test "controller with form_inputs provides data for TypeScript generation" do
      defmodule IntegrationTestController do
        use NbInertia.Controller

        inertia_page :users_new do
          prop(:errors, :map, default: %{})

          form_inputs :user do
            field(:name, :string)
            field(:email, :string)
            field(:age, :integer, optional: true)
            field(:bio, :string, optional: true)
          end
        end

        inertia_page :settings do
          form_inputs :profile do
            field(:display_name, :string)
          end

          form_inputs :password do
            field(:current_password, :string)
            field(:new_password, :string)
          end
        end
      end

      # Verify forms are accessible via __inertia_forms__/0
      assert function_exported?(IntegrationTestController, :__inertia_forms__, 0)

      forms = IntegrationTestController.__inertia_forms__()

      # Verify forms map structure
      assert is_map(forms)
      assert Map.has_key?(forms, :user)
      assert Map.has_key?(forms, :profile)
      assert Map.has_key?(forms, :password)

      # Verify user form fields
      user_form = forms[:user]
      assert is_list(user_form)
      assert length(user_form) == 4

      # Verify field structure {name, type, opts}
      assert {:name, :string, []} in user_form
      assert {:email, :string, []} in user_form
      assert {:age, :integer, [optional: true]} in user_form
      assert {:bio, :string, [optional: true]} in user_form

      # Verify profile form
      profile_form = forms[:profile]
      assert [{:display_name, :string, []}] = profile_form

      # Verify password form
      password_form = forms[:password]
      assert length(password_form) == 2
      assert {:current_password, :string, []} in password_form
      assert {:new_password, :string, []} in password_form
    end

    test "form definitions persist across multiple pages" do
      defmodule MultiPageController do
        use NbInertia.Controller

        inertia_page :page_one do
          form_inputs :form_a do
            field(:field1, :string)
          end
        end

        inertia_page :page_two do
          form_inputs :form_b do
            field(:field2, :number)
          end
        end
      end

      forms = MultiPageController.__inertia_forms__()

      # Both forms should be available
      assert Map.has_key?(forms, :form_a)
      assert Map.has_key?(forms, :form_b)
    end

    test "supports all type mappings required by nb_ts" do
      defmodule AllTypesController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field(:str_field, :string)
            field(:num_field, :number)
            field(:int_field, :integer)
            field(:bool_field, :boolean)
            field(:any_field, :any)
            field(:date_field, :date)
            field(:datetime_field, :datetime)
            field(:map_field, :map)
          end
        end
      end

      forms = AllTypesController.__inertia_forms__()
      data_form = forms[:data]

      # Verify all types are present
      field_types =
        data_form
        |> Enum.map(fn {_name, type, _opts} -> type end)
        |> MapSet.new()

      assert :string in field_types
      assert :number in field_types
      assert :integer in field_types
      assert :boolean in field_types
      assert :any in field_types
      assert :date in field_types
      assert :datetime in field_types
      assert :map in field_types
    end

    test "optional fields have correct metadata" do
      defmodule OptionalFieldsController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field(:required_field, :string)
            field(:optional_field, :string, optional: true)
          end
        end
      end

      forms = OptionalFieldsController.__inertia_forms__()
      data_form = forms[:data]

      # Find required field
      {_name, _type, required_opts} =
        Enum.find(data_form, fn {name, _type, _opts} -> name == :required_field end)

      assert Keyword.get(required_opts, :optional, false) == false

      # Find optional field
      {_name, _type, optional_opts} =
        Enum.find(data_form, fn {name, _type, _opts} -> name == :optional_field end)

      assert Keyword.get(optional_opts, :optional) == true
    end

    test "form_inputs can coexist with regular props" do
      defmodule MixedPropsController do
        use NbInertia.Controller

        inertia_page :mixed do
          prop(:user, :map)
          prop(:settings, :map, default: %{})

          form_inputs :edit_form do
            field(:name, :string)
          end
        end
      end

      # Verify both systems work
      pages = MixedPropsController.__inertia_pages__()
      forms = MixedPropsController.__inertia_forms__()

      # Props should be defined
      assert Map.has_key?(pages, :mixed)
      mixed_page = pages[:mixed]
      assert length(mixed_page.props) == 2

      # Forms should be defined
      assert Map.has_key?(forms, :edit_form)
    end
  end

  describe "nested list fields integration" do
    test "controller with nested list fields provides correct data structure" do
      defmodule NestedListController do
        use NbInertia.Controller

        inertia_page :spaces_new do
          form_inputs :space do
            field(:name, :string)

            field :questions, :list do
              field(:question_text, :string)
              field(:required, :boolean)
              field(:position, :integer)
            end
          end
        end
      end

      forms = NestedListController.__inertia_forms__()

      # Verify space form exists
      assert Map.has_key?(forms, :space)
      space_form = forms[:space]

      # Should have 2 fields: name and questions
      assert length(space_form) == 2

      # First field is regular string
      assert {:name, :string, []} = Enum.at(space_form, 0)

      # Second field is nested list (4-tuple format)
      {field_name, field_type, field_opts, nested_fields} = Enum.at(space_form, 1)
      assert field_name == :questions
      assert field_type == :list
      assert field_opts == []
      assert is_list(nested_fields)
      assert length(nested_fields) == 3

      # Verify nested field structure
      assert {:question_text, :string, []} in nested_fields
      assert {:required, :boolean, []} in nested_fields
      assert {:position, :integer, []} in nested_fields
    end

    test "nested list fields with optional outer field" do
      defmodule OptionalNestedController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field(:name, :string)

            field :items, :list, optional: true do
              field(:label, :string)
            end
          end
        end
      end

      forms = OptionalNestedController.__inertia_forms__()
      data_form = forms[:data]

      # Find the nested list field
      {_name, :list, opts, nested} =
        Enum.find(data_form, fn field ->
          case field do
            {_name, :list, _opts, _nested} -> true
            _ -> false
          end
        end)

      # Should be optional
      assert Keyword.get(opts, :optional) == true

      # Nested field should be present
      assert [{:label, :string, []}] = nested
    end

    test "nested list fields with optional inner fields" do
      defmodule OptionalInnerFieldsController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field :items, :list do
              field(:name, :string)
              field(:description, :string, optional: true)
              field(:required, :boolean)
            end
          end
        end
      end

      forms = OptionalInnerFieldsController.__inertia_forms__()
      data_form = forms[:data]

      # Get nested fields
      {_name, :list, _opts, nested_fields} = Enum.at(data_form, 0)

      # Verify optional metadata on inner fields
      {_name, _type, name_opts} =
        Enum.find(nested_fields, fn {name, _type, _opts} -> name == :name end)

      assert Keyword.get(name_opts, :optional, false) == false

      {_name, _type, desc_opts} =
        Enum.find(nested_fields, fn {name, _type, _opts} -> name == :description end)

      assert Keyword.get(desc_opts, :optional) == true
    end

    test "multiple nested list fields in same form" do
      defmodule MultipleNestedListsController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field :questions, :list do
              field(:text, :string)
            end

            field :answers, :list do
              field(:value, :string)
            end
          end
        end
      end

      forms = MultipleNestedListsController.__inertia_forms__()
      data_form = forms[:data]

      # Should have 2 nested list fields
      nested_count =
        Enum.count(data_form, fn field ->
          case field do
            {_name, :list, _opts, _nested} -> true
            _ -> false
          end
        end)

      assert nested_count == 2

      # Verify both have their nested structures
      {_name, :list, _opts, questions_nested} = Enum.at(data_form, 0)
      assert [{:text, :string, []}] = questions_nested

      {_name, :list, _opts, answers_nested} = Enum.at(data_form, 1)
      assert [{:value, :string, []}] = answers_nested
    end
  end

  describe "data format for nb_ts consumption" do
    test "forms use consistent tuple format {name, type, opts}" do
      defmodule FormatTestController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field(:field1, :string)
            field(:field2, :number, optional: true)
          end
        end
      end

      forms = FormatTestController.__inertia_forms__()
      fields = forms[:data]

      # Every field should be a 3-tuple
      Enum.each(fields, fn field ->
        assert is_tuple(field)
        assert tuple_size(field) == 3

        {name, type, opts} = field
        assert is_atom(name)
        assert is_atom(type)
        assert is_list(opts)
      end)
    end

    test "nested list fields use 4-tuple format {name, :list, opts, nested_fields}" do
      defmodule NestedFormatController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field :items, :list do
              field(:name, :string)
            end
          end
        end
      end

      forms = NestedFormatController.__inertia_forms__()
      fields = forms[:data]

      # Nested list field should be a 4-tuple
      assert [{name, type, opts, nested_fields}] = fields

      assert name == :items
      assert type == :list
      assert is_list(opts)
      assert is_list(nested_fields)

      # Nested fields should be 3-tuples
      Enum.each(nested_fields, fn field ->
        assert is_tuple(field)
        assert tuple_size(field) == 3
      end)
    end

    test "field order is preserved" do
      defmodule OrderTestController do
        use NbInertia.Controller

        inertia_page :test do
          form_inputs :data do
            field(:first, :string)
            field(:second, :string)
            field(:third, :string)
          end
        end
      end

      forms = OrderTestController.__inertia_forms__()
      fields = forms[:data]

      field_names = Enum.map(fields, fn {name, _type, _opts} -> name end)
      assert field_names == [:first, :second, :third]
    end
  end
end
