defmodule NbInertia.ExampleControllerTest do
  use ExUnit.Case, async: true

  alias NbInertia.ExampleController

  describe "form definitions introspection" do
    test "user form definition (last definition wins)" do
      forms = ExampleController.__inertia_forms__()

      # Note: Both :users_new and :users_edit define a :user form
      # The last definition (:users_edit) wins in the current implementation
      # This is acceptable as forms will be scoped by page in TypeScript generation
      assert forms[:user] == [
               {:name, :string, []},
               {:email, :string, []},
               {:age, :integer, [optional: true]},
               {:bio, :string, [optional: true]},
               {:notify_by_email, :boolean, [optional: true]}
             ]
    end

    test "company_settings page has multiple forms" do
      forms = ExampleController.__inertia_forms__()

      # Company form
      assert forms[:company] == [
               {:name, :string, []},
               {:tax_id, :string, []},
               {:website, :string, [optional: true]}
             ]

      # Billing form
      assert forms[:billing] == [
               {:address, :string, []},
               {:city, :string, []},
               {:postal_code, :string, []},
               {:country, :string, []}
             ]
    end

    test "profile_complete has all supported types" do
      forms = ExampleController.__inertia_forms__()

      assert forms[:profile] == [
               {:full_name, :string, []},
               {:username, :string, []},
               {:age, :integer, []},
               {:height_cm, :number, [optional: true]},
               {:subscribed, :boolean, []},
               {:birthday, :date, [optional: true]},
               {:last_login, :datetime, [optional: true]},
               {:preferences, :map, [optional: true]},
               {:custom_data, :any, [optional: true]}
             ]
    end

    test "contact page has simple message form" do
      forms = ExampleController.__inertia_forms__()

      assert forms[:message] == [
               {:name, :string, []},
               {:email, :string, []},
               {:subject, :string, []},
               {:body, :string, []}
             ]
    end

    test "all forms are present" do
      forms = ExampleController.__inertia_forms__()

      # We should have forms for user, company, billing, profile, and message
      assert Map.has_key?(forms, :user)
      assert Map.has_key?(forms, :company)
      assert Map.has_key?(forms, :billing)
      assert Map.has_key?(forms, :profile)
      assert Map.has_key?(forms, :message)
    end
  end
end
