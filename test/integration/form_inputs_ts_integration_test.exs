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
