defmodule NbInertia.ExampleController do
  @moduledoc """
  Example controller demonstrating the form_inputs DSL for TypeScript type generation.

  This controller shows how to define form input schemas that will be used to
  generate TypeScript types for type-safe forms in your frontend.
  """

  use NbInertia.Controller

  # Example 1: Simple user registration form
  inertia_page :users_new do
    prop(:user, :map)

    form_inputs :user do
      field(:name, :string)
      field(:email, :string)
      field(:password, :string)
      field(:password_confirmation, :string)
      field(:age, :integer, optional: true)
      field(:bio, :string, optional: true)
    end
  end

  # Example 2: User edit form with optional fields
  inertia_page :users_edit do
    prop(:user, :map)

    form_inputs :user do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer, optional: true)
      field(:bio, :string, optional: true)
      field(:notify_by_email, :boolean, optional: true)
    end
  end

  # Example 3: Multiple forms on the same page
  inertia_page :company_settings do
    prop(:company, :map)
    prop(:billing, :map)

    form_inputs :company do
      field(:name, :string)
      field(:tax_id, :string)
      field(:website, :string, optional: true)
    end

    form_inputs :billing do
      field(:address, :string)
      field(:city, :string)
      field(:postal_code, :string)
      field(:country, :string)
    end
  end

  # Example 4: Form with all supported types
  inertia_page :profile_complete do
    form_inputs :profile do
      field(:full_name, :string)
      field(:username, :string)
      field(:age, :integer)
      field(:height_cm, :number, optional: true)
      field(:subscribed, :boolean)
      field(:birthday, :date, optional: true)
      field(:last_login, :datetime, optional: true)
      field(:preferences, :map, optional: true)
      field(:custom_data, :any, optional: true)
    end
  end

  # Example 5: Simple contact form
  inertia_page :contact do
    form_inputs :message do
      field(:name, :string)
      field(:email, :string)
      field(:subject, :string)
      field(:body, :string)
    end
  end
end
