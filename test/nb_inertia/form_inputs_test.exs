defmodule NbInertia.FormInputsTest do
  use ExUnit.Case, async: true

  describe "form_inputs macro" do
    test "stores form definitions correctly" do
      defmodule TestController1 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:name, :string)
            field(:email, :string)
          end
        end
      end

      forms = TestController1.__inertia_forms__()

      assert forms[:user] == [
               {:name, :string, []},
               {:email, :string, []}
             ]
    end

    test "stores fields with types and options" do
      defmodule TestController2 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:name, :string)
            field(:age, :integer, optional: true)
            field(:bio, :string, optional: true)
          end
        end
      end

      forms = TestController2.__inertia_forms__()

      assert forms[:user] == [
               {:name, :string, []},
               {:age, :integer, [optional: true]},
               {:bio, :string, [optional: true]}
             ]
    end

    test "supports multiple forms per page" do
      defmodule TestController3 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:name, :string)
          end

          form_inputs :company do
            field(:company_name, :string)
            field(:tax_id, :string)
          end
        end
      end

      forms = TestController3.__inertia_forms__()
      assert forms[:user] == [{:name, :string, []}]

      assert forms[:company] == [
               {:company_name, :string, []},
               {:tax_id, :string, []}
             ]
    end

    test "returns empty map when no forms defined" do
      defmodule TestController4 do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:data, :string)
        end
      end

      forms = TestController4.__inertia_forms__()
      assert forms == %{}
    end

    test "supports all basic types" do
      defmodule TestController5 do
        use NbInertia.Controller

        inertia_page :test_page do
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

      forms = TestController5.__inertia_forms__()

      assert forms[:data] == [
               {:str_field, :string, []},
               {:num_field, :number, []},
               {:int_field, :integer, []},
               {:bool_field, :boolean, []},
               {:any_field, :any, []},
               {:date_field, :date, []},
               {:datetime_field, :datetime, []},
               {:map_field, :map, []}
             ]
    end

    test "form can be defined in different pages" do
      defmodule TestController6 do
        use NbInertia.Controller

        inertia_page :users_new do
          form_inputs :user do
            field(:name, :string)
          end
        end

        inertia_page :users_edit do
          form_inputs :user do
            field(:name, :string)
            field(:email, :string)
          end
        end
      end

      # Both pages should have their own form definitions
      forms = TestController6.__inertia_forms__()
      # Note: Since we're using the same form name :user in different pages,
      # the last one wins in the current implementation
      # This is acceptable as forms are scoped by page in the TypeScript generation
      assert forms[:user] == [
               {:name, :string, []},
               {:email, :string, []}
             ]
    end
  end

  describe "field macro" do
    test "raises error when used outside form_inputs block" do
      assert_raise CompileError, ~r/field\/3 must be used inside a form_inputs block/, fn ->
        defmodule BadController1 do
          use NbInertia.Controller

          inertia_page :test_page do
            field(:name, :string)
          end
        end
      end
    end

    test "raises error when used outside any inertia_page" do
      assert_raise CompileError, ~r/field\/3 must be used inside a form_inputs block/, fn ->
        defmodule BadController2 do
          use NbInertia.Controller

          field(:name, :string)
        end
      end
    end

    test "accepts optional option" do
      defmodule TestController7 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:required_field, :string)
            field(:optional_field, :string, optional: true)
          end
        end
      end

      forms = TestController7.__inertia_forms__()

      assert forms[:user] == [
               {:required_field, :string, []},
               {:optional_field, :string, [optional: true]}
             ]
    end

    test "preserves field order" do
      defmodule TestController8 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:first, :string)
            field(:second, :integer)
            field(:third, :boolean)
          end
        end
      end

      forms = TestController8.__inertia_forms__()

      assert forms[:user] == [
               {:first, :string, []},
               {:second, :integer, []},
               {:third, :boolean, []}
             ]
    end

    test "allows custom options beyond optional" do
      defmodule TestController9 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :user do
            field(:name, :string, optional: true, custom_meta: "value")
          end
        end
      end

      forms = TestController9.__inertia_forms__()

      assert forms[:user] == [
               {:name, :string, [optional: true, custom_meta: "value"]}
             ]
    end
  end

  describe "nested list fields" do
    test "supports nested block syntax for list fields" do
      defmodule TestController12 do
        use NbInertia.Controller

        inertia_page :test_page do
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

      forms = TestController12.__inertia_forms__()

      assert forms[:space] == [
               {:name, :string, []},
               {:questions, :list, [],
                [
                  {:question_text, :string, []},
                  {:required, :boolean, []},
                  {:position, :integer, []}
                ]}
             ]
    end

    test "supports optional nested list fields" do
      defmodule TestController13 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :space do
            field(:name, :string)

            field :questions, :list, optional: true do
              field(:text, :string)
            end
          end
        end
      end

      forms = TestController13.__inertia_forms__()

      assert forms[:space] == [
               {:name, :string, []},
               {:questions, :list, [optional: true], [{:text, :string, []}]}
             ]
    end

    test "supports multiple nested list fields" do
      defmodule TestController14 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :space do
            field :questions, :list do
              field(:text, :string)
            end

            field :answers, :list do
              field(:value, :string)
            end
          end
        end
      end

      forms = TestController14.__inertia_forms__()

      assert forms[:space] == [
               {:questions, :list, [], [{:text, :string, []}]},
               {:answers, :list, [], [{:value, :string, []}]}
             ]
    end

    test "supports nested fields with mixed optional/required" do
      defmodule TestController15 do
        use NbInertia.Controller

        inertia_page :test_page do
          form_inputs :space do
            field :questions, :list do
              field(:text, :string)
              field(:hint, :string, optional: true)
              field(:required, :boolean)
            end
          end
        end
      end

      forms = TestController15.__inertia_forms__()

      assert forms[:space] == [
               {:questions, :list, [],
                [
                  {:text, :string, []},
                  {:hint, :string, [optional: true]},
                  {:required, :boolean, []}
                ]}
             ]
    end

    test "raises error when using block with non-list type" do
      assert_raise CompileError,
                   ~r/field with nested block must have type :list/,
                   fn ->
                     defmodule BadController3 do
                       use NbInertia.Controller

                       inertia_page :test_page do
                         form_inputs :data do
                           field :name, :string do
                             field(:nested, :string)
                           end
                         end
                       end
                     end
                   end
    end

    test "raises error when nested field used outside parent field block" do
      # This should already be caught by the existing validation
      assert_raise CompileError, ~r/field\/3 must be used inside a form_inputs block/, fn ->
        defmodule BadController4 do
          use NbInertia.Controller

          inertia_page :test_page do
            field(:name, :string)
          end
        end
      end
    end
  end

  describe "integration with inertia_page" do
    test "form_inputs works alongside prop definitions" do
      defmodule TestController10 do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:existing_user, :map)

          form_inputs :user do
            field(:name, :string)
          end
        end
      end

      # Check both props and forms are stored
      pages = TestController10.__inertia_pages__()
      assert pages[:test_page].props == [%{name: :existing_user, type: :map, opts: []}]

      forms = TestController10.__inertia_forms__()
      assert forms[:user] == [{:name, :string, []}]
    end

    test "multiple pages each with their own forms" do
      defmodule TestController11 do
        use NbInertia.Controller

        inertia_page :page_one do
          form_inputs :form_a do
            field(:field_a, :string)
          end
        end

        inertia_page :page_two do
          form_inputs :form_b do
            field(:field_b, :integer)
          end
        end
      end

      forms = TestController11.__inertia_forms__()
      # Both forms should exist
      assert forms[:form_a] == [{:field_a, :string, []}]
      assert forms[:form_b] == [{:field_b, :integer, []}]
    end

    test "form_inputs with nested list fields works alongside props" do
      defmodule TestController16 do
        use NbInertia.Controller

        inertia_page :test_page do
          prop(:space, :map)

          form_inputs :space do
            field(:name, :string)

            field :questions, :list do
              field(:text, :string)
            end
          end
        end
      end

      pages = TestController16.__inertia_pages__()
      assert pages[:test_page].props == [%{name: :space, type: :map, opts: []}]

      forms = TestController16.__inertia_forms__()

      assert forms[:space] == [
               {:name, :string, []},
               {:questions, :list, [], [{:text, :string, []}]}
             ]
    end
  end
end
