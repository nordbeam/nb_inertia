defmodule NbInertia.Plugs.Precognition do
  @moduledoc """
  Plug to handle Precognition validation requests for real-time form validation.

  Precognition allows real-time form validation by sending validation requests
  to the server before form submission. This plug intercepts these requests
  and handles validation-only responses.

  ## Protocol

  Precognition requests are identified by the `Precognition: true` header.
  The `Precognition-Validate-Only` header contains a comma-separated list
  of fields to validate.

  ### Request Headers

    * `Precognition: true` - Indicates this is a Precognition request
    * `Precognition-Validate-Only: name,email` - Fields to validate (optional)

  ### Response Headers

    * `Precognition: true` - Confirms this is a Precognition response
    * `Precognition-Success: true` - Indicates validation passed (with 204)
    * `Vary: Precognition` - Cache variation header

  ### Response Codes

    * `204 No Content` - Validation passed with no errors
    * `422 Unprocessable Entity` - Validation errors exist (JSON body with errors)

  ## Setup

  Add this plug to your router pipeline:

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug NbInertia.Plugs.Precognition
      end

  ## Usage with validate_precognition/3

  In your controller, use `validate_precognition/3` to handle validation:

      def create(conn, %{"user" => user_params}) do
        changeset = User.changeset(%User{}, user_params)

        # Handle Precognition validation requests
        case validate_precognition(conn, changeset) do
          {:precognition, conn} ->
            # Precognition handled the response, we're done
            conn

          {:ok, conn} ->
            # Not a Precognition request, proceed normally
            case Accounts.create_user(user_params) do
              {:ok, user} ->
                conn
                |> put_flash(:info, "User created!")
                |> redirect(to: ~p"/users/\#{user.id}")

              {:error, changeset} ->
                render_inertia(conn, :users_new, changeset: changeset)
            end
        end
      end

  ## Usage with precognition/3 macro

  For simpler cases, use the `precognition/3` macro:

      use NbInertia.Plugs.Precognition

      def create(conn, %{"user" => user_params}) do
        changeset = User.changeset(%User{}, user_params)

        precognition conn, changeset do
          # This block only runs for real submissions
          case Accounts.create_user(user_params) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "User created!")
              |> redirect(to: ~p"/users/\#{user.id}")

            {:error, changeset} ->
              render_inertia(conn, :users_new, changeset: changeset)
          end
        end
      end

  ## Respecting Precognition-Validate-Only

  The `Precognition-Validate-Only` header specifies which fields to validate.
  Use the `:only` option with `precognition_fields/1` to respect this:

      precognition conn, changeset, only: precognition_fields(conn) do
        # ...
      end

  Or with validate_precognition/3:

      validate_precognition(conn, changeset, only: precognition_fields(conn))

  ## With Custom Validation

  You can also use custom validation logic with an error map:

      def create(conn, %{"payment" => params}) do
        errors = validate_payment(params)  # Returns %{} or %{field: ["error"]}

        case validate_precognition(conn, errors) do
          {:precognition, conn} -> conn
          {:ok, conn} ->
            # Real submission logic...
        end
      end

  ## Frontend Integration

  Use Inertia.js v2.3+ Precognition with nb_routes:

      import { useForm } from '@inertiajs/react';
      import { store_user_path } from '@/routes';

      // Enable Precognition with RouteResult
      const form = useForm({ name: '', email: '' })
        .withPrecognition(store_user_path.post());

      // Or use shorthand (same endpoint for validation AND submission)
      const form = useForm(store_user_path.post(), { name: '', email: '' });

      // Validate on blur
      <input
        value={form.data.name}
        onChange={e => form.setData('name', e.target.value)}
        onBlur={() => form.validate('name')}
      />
      {form.invalid('name') && <span>{form.errors.name}</span>}
      {form.validating && <span>Validating...</span>}
  """

  import Plug.Conn

  @behaviour Plug

  @precognition_header "precognition"
  @precognition_validate_only_header "precognition-validate-only"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn
    |> extract_precognition_flag()
    |> extract_validate_only_fields()
  end

  # Private functions for plug

  defp extract_precognition_flag(conn) do
    case get_req_header(conn, @precognition_header) do
      ["true" | _] ->
        put_private(conn, :precognition, true)

      _ ->
        put_private(conn, :precognition, false)
    end
  end

  defp extract_validate_only_fields(conn) do
    case get_req_header(conn, @precognition_validate_only_header) do
      [fields | _] when is_binary(fields) and fields != "" ->
        field_list =
          fields
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        put_private(conn, :precognition_validate_only, field_list)

      _ ->
        put_private(conn, :precognition_validate_only, nil)
    end
  end

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Checks if the current request is a Precognition validation request.

  ## Examples

      if precognition_request?(conn) do
        # Handle validation only
      end
  """
  @spec precognition_request?(Plug.Conn.t()) :: boolean()
  def precognition_request?(conn) do
    conn.private[:precognition] == true
  end

  @doc """
  Returns the fields specified in the `Precognition-Validate-Only` header.

  Returns `nil` if the header is not present (validate all fields).

  ## Examples

      case precognition_fields(conn) do
        nil -> validate_all_fields(changeset)
        fields -> validate_only_fields(changeset, fields)
      end
  """
  @spec precognition_fields(Plug.Conn.t()) :: [String.t()] | nil
  def precognition_fields(conn) do
    conn.private[:precognition_validate_only]
  end

  @doc """
  Validates a changeset or error map for Precognition requests.

  If this is a Precognition request, sends the appropriate response and returns
  `{:precognition, conn}`. Otherwise returns `{:ok, conn}`.

  ## Parameters

    * `conn` - The connection struct
    * `validatable` - An `Ecto.Changeset` or error map (`%{field => [errors]}`)
    * `opts` - Options (see below)

  ## Options

    * `:only` - List of fields to validate (from `precognition_fields/1`)
    * `:camelize` - Whether to camelize error keys (default: from config)

  ## Returns

    * `{:precognition, conn}` - If this was a Precognition request (response sent)
    * `{:ok, conn}` - If this was not a Precognition request (proceed normally)

  ## Examples

      # Basic usage
      case validate_precognition(conn, changeset) do
        {:precognition, conn} -> conn
        {:ok, conn} -> # proceed with normal logic
      end

      # With field filtering
      case validate_precognition(conn, changeset, only: precognition_fields(conn)) do
        {:precognition, conn} -> conn
        {:ok, conn} -> # proceed with normal logic
      end
  """
  @spec validate_precognition(Plug.Conn.t(), Ecto.Changeset.t() | map(), keyword()) ::
          {:precognition, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def validate_precognition(conn, validatable, opts \\ [])

  def validate_precognition(conn, %Ecto.Changeset{} = changeset, opts) do
    if precognition_request?(conn) do
      errors = extract_changeset_errors(changeset, opts)
      {:precognition, send_precognition_response(conn, errors)}
    else
      {:ok, conn}
    end
  end

  def validate_precognition(conn, errors, opts) when is_map(errors) do
    if precognition_request?(conn) do
      filtered_errors = filter_errors(errors, opts)
      {:precognition, send_precognition_response(conn, filtered_errors)}
    else
      {:ok, conn}
    end
  end

  @doc """
  Sends a Precognition validation response.

  This is a lower-level function for custom validation scenarios.

  ## Parameters

    * `conn` - The connection struct
    * `errors` - Error map (`%{field => [errors]}` or `%{}` for success)

  ## Response Format

  Success (no errors):
  - Status: 204 No Content
  - Headers: `Precognition: true`, `Precognition-Success: true`, `Vary: Precognition`

  Failure (has errors):
  - Status: 422 Unprocessable Entity
  - Headers: `Precognition: true`, `Vary: Precognition`
  - Body: `{"errors": {"field": "error message"}}`

  ## Examples

      errors = validate_payment(params)
      send_precognition_response(conn, errors)
  """
  @spec send_precognition_response(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send_precognition_response(conn, errors) when map_size(errors) == 0 do
    # Validation passed - return 204 No Content
    conn
    |> put_resp_header("precognition", "true")
    |> put_resp_header("precognition-success", "true")
    |> put_resp_header("vary", "Precognition")
    |> send_resp(204, "")
    |> halt()
  end

  def send_precognition_response(conn, errors) do
    # Validation failed - return 422 with errors
    conn
    |> put_resp_header("precognition", "true")
    |> put_resp_header("vary", "Precognition")
    |> put_resp_content_type("application/json")
    |> send_resp(422, Jason.encode!(%{errors: errors}))
    |> halt()
  end

  # ============================================================================
  # Macro for cleaner controller code
  # ============================================================================

  @doc """
  Provides the `precognition/3` macro for controllers.

  ## Usage

      use NbInertia.Plugs.Precognition

      def create(conn, %{"user" => params}) do
        changeset = User.changeset(%User{}, params)

        precognition conn, changeset do
          # This only runs for real submissions
          case Accounts.create_user(params) do
            {:ok, user} -> redirect(conn, to: ~p"/users/\#{user.id}")
            {:error, changeset} -> render_inertia(conn, :new, changeset: changeset)
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      import NbInertia.Plugs.Precognition,
        only: [
          precognition: 3,
          precognition: 4,
          precognition_request?: 1,
          precognition_fields: 1,
          validate_precognition: 2,
          validate_precognition: 3,
          send_precognition_response: 2
        ]
    end
  end

  @doc """
  Macro that handles Precognition validation automatically.

  If the request is a Precognition request, validates and returns early.
  Otherwise, executes the do block.

  ## Examples

      precognition conn, changeset do
        # This only runs for real form submissions
        case Repo.insert(changeset) do
          {:ok, record} -> redirect(conn, to: "/success")
          {:error, changeset} -> render(conn, :form, changeset: changeset)
        end
      end

      # With options
      precognition conn, changeset, only: precognition_fields(conn) do
        # ...
      end
  """
  defmacro precognition(conn, validatable, do: block) do
    quote do
      case NbInertia.Plugs.Precognition.validate_precognition(unquote(conn), unquote(validatable)) do
        {:precognition, conn} ->
          conn

        {:ok, var!(conn)} ->
          unquote(block)
      end
    end
  end

  defmacro precognition(conn, validatable, opts, do: block) do
    quote do
      case NbInertia.Plugs.Precognition.validate_precognition(
             unquote(conn),
             unquote(validatable),
             unquote(opts)
           ) do
        {:precognition, conn} ->
          conn

        {:ok, var!(conn)} ->
          unquote(block)
      end
    end
  end

  # ============================================================================
  # Private helpers
  # ============================================================================

  defp extract_changeset_errors(changeset, opts) do
    # Use Ecto.Changeset.traverse_errors to get all errors
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    filter_errors(errors, opts)
  end

  defp filter_errors(errors, opts) do
    only_fields = Keyword.get(opts, :only)
    camelize? = Keyword.get(opts, :camelize, NbInertia.Config.camelize_props?())

    errors
    |> maybe_filter_fields(only_fields)
    |> maybe_camelize_keys(camelize?)
  end

  defp maybe_filter_fields(errors, nil), do: errors

  defp maybe_filter_fields(errors, only_fields) when is_list(only_fields) do
    # Convert string field names to atoms for comparison
    only_atoms = Enum.map(only_fields, &maybe_to_atom/1)

    Map.filter(errors, fn {key, _value} ->
      key in only_atoms or to_string(key) in only_fields
    end)
  end

  defp maybe_to_atom(field) when is_binary(field) do
    try do
      String.to_existing_atom(field)
    rescue
      ArgumentError -> field
    end
  end

  defp maybe_to_atom(field), do: field

  defp maybe_camelize_keys(errors, false), do: errors

  defp maybe_camelize_keys(errors, true) do
    Map.new(errors, fn {key, value} ->
      camelized_key = camelize_key(key)
      {camelized_key, value}
    end)
  end

  defp camelize_key(key) when is_atom(key) do
    key |> to_string() |> camelize_string()
  end

  defp camelize_key(key) when is_binary(key) do
    camelize_string(key)
  end

  defp camelize_string(string) do
    # Convert snake_case to camelCase
    string
    |> String.split("_")
    |> Enum.with_index()
    |> Enum.map(fn
      {word, 0} -> String.downcase(word)
      {word, _} -> String.capitalize(word)
    end)
    |> Enum.join()
  end
end
