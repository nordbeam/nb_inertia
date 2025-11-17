defmodule NbInertia.Modal.Redirector do
  @moduledoc """
  Helpers for redirecting and closing modals after actions.

  This module provides functions for redirecting after modal actions (like form
  submissions) while properly closing the modal and handling flash messages.

  ## Usage

  After processing a form submission in a modal, you typically want to:
  1. Close the modal
  2. Redirect to the base page (or another page)
  3. Show a success/error flash message

  This module makes that easy:

      def create(conn, params) do
        case MyApp.create_user(params) do
          {:ok, user} ->
            conn
            |> put_flash(:info, "User created successfully")
            |> redirect_modal(to: users_path())

          {:error, changeset} ->
            render_inertia_modal(conn, :new_user,
              [form: changeset],
              base_url: users_path()
            )
        end
      end

  ## How It Works

  The `redirect_modal/2` function:
  1. Adds a special header (`x-inertia-modal-redirect`) to signal modal closure
  2. Preserves flash messages for the redirected page
  3. Performs a standard Inertia redirect

  The frontend modal components detect this header and close the modal before
  handling the redirect.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias NbInertia.Modal

  @modal_redirect_header "x-inertia-modal-redirect"

  @doc """
  Returns the custom header name for indicating a modal redirect.

  ## Example

      iex> NbInertia.Modal.Redirector.modal_redirect_header()
      "x-inertia-modal-redirect"
  """
  @spec modal_redirect_header() :: String.t()
  def modal_redirect_header, do: @modal_redirect_header

  @doc """
  Redirects and closes the modal.

  This is typically used after successfully processing a modal form submission.
  The modal will be closed on the frontend before the redirect happens.

  ## Parameters

    - `conn` - The Plug.Conn struct
    - `opts` - Redirect options (same as Phoenix.Controller.redirect/2)

  ## Options

    - `:to` - The path to redirect to (string or RouteResult)
    - `:external` - External URL to redirect to

  ## Examples

      # Basic redirect with flash message
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect_modal(to: "/users")

      # Redirect with nb_routes RouteResult
      conn
      |> put_flash(:success, "Post published")
      |> redirect_modal(to: posts_path())

      # Redirect with error flash
      conn
      |> put_flash(:error, "Failed to delete item")
      |> redirect_modal(to: items_path())

      # External redirect
      conn
      |> redirect_modal(external: "https://example.com")
  """
  @spec redirect_modal(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def redirect_modal(conn, opts) do
    # Extract redirect URL from opts
    redirect_url = extract_redirect_url(opts)

    conn
    |> put_resp_header(@modal_redirect_header, "true")
    |> put_resp_header(Modal.modal_header(), "false")
    |> redirect(to: redirect_url)
  end

  @doc """
  Redirects and closes the modal with a success flash message.

  Convenience function that combines flash message and redirect.

  ## Parameters

    - `conn` - The Plug.Conn struct
    - `message` - The success message to display
    - `opts` - Redirect options

  ## Examples

      redirect_modal_success(conn, "User created!", to: users_path())
  """
  @spec redirect_modal_success(Plug.Conn.t(), String.t(), keyword()) :: Plug.Conn.t()
  def redirect_modal_success(conn, message, opts) do
    conn
    |> Phoenix.Controller.put_flash(:info, message)
    |> redirect_modal(opts)
  end

  @doc """
  Redirects and closes the modal with an error flash message.

  Convenience function that combines flash message and redirect.

  ## Parameters

    - `conn` - The Plug.Conn struct
    - `message` - The error message to display
    - `opts` - Redirect options

  ## Examples

      redirect_modal_error(conn, "Failed to save user", to: users_path())
  """
  @spec redirect_modal_error(Plug.Conn.t(), String.t(), keyword()) :: Plug.Conn.t()
  def redirect_modal_error(conn, message, opts) do
    conn
    |> Phoenix.Controller.put_flash(:error, message)
    |> redirect_modal(opts)
  end

  @doc """
  Closes the modal without redirecting.

  This is useful when you want to close the modal and refresh the current page.
  The frontend will detect this header and close the modal, then refresh.

  ## Parameters

    - `conn` - The Plug.Conn struct

  ## Examples

      # Close modal and refresh current page
      conn
      |> put_flash(:info, "Settings saved")
      |> close_modal()
  """
  @spec close_modal(Plug.Conn.t()) :: Plug.Conn.t()
  def close_modal(conn) do
    # Get the base URL from the modal request headers
    base_url =
      case get_req_header(conn, Modal.modal_base_url_header()) do
        [url | _] when is_binary(url) -> url
        _ -> conn.request_path
      end

    conn
    |> put_resp_header(@modal_redirect_header, "true")
    |> put_resp_header(Modal.modal_header(), "false")
    |> redirect(to: base_url)
  end

  @doc """
  Checks if the current redirect is a modal redirect.

  This can be used in after-action hooks or middleware to detect modal redirects.

  ## Parameters

    - `conn` - The Plug.Conn struct

  ## Example

      if Redirector.modal_redirect?(conn) do
        # Handle modal redirect specially
      end
  """
  @spec modal_redirect?(Plug.Conn.t()) :: boolean()
  def modal_redirect?(conn) do
    case get_resp_header(conn, @modal_redirect_header) do
      ["true" | _] -> true
      _ -> false
    end
  end

  @doc """
  Checks if the current request is from a modal.

  This checks the incoming request headers to determine if the request
  originated from a modal.

  ## Parameters

    - `conn` - The Plug.Conn struct

  ## Example

      if Redirector.from_modal?(conn) do
        # This request came from a modal
      end
  """
  @spec from_modal?(Plug.Conn.t()) :: boolean()
  def from_modal?(conn) do
    case get_req_header(conn, Modal.modal_header()) do
      ["true" | _] -> true
      _ -> false
    end
  end

  # Private helpers

  defp extract_redirect_url(opts) do
    cond do
      Keyword.has_key?(opts, :to) ->
        case Keyword.get(opts, :to) do
          # Handle nb_routes RouteResult
          %{url: url} when is_binary(url) -> url
          # Handle plain string
          url when is_binary(url) -> url
          # Invalid type
          other -> raise ArgumentError, "Invalid :to option: #{inspect(other)}"
        end

      Keyword.has_key?(opts, :external) ->
        Keyword.get(opts, :external)

      true ->
        raise ArgumentError, "redirect_modal/2 requires either :to or :external option"
    end
  end
end
