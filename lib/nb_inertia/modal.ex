defmodule NbInertia.Modal do
  @moduledoc """
  Modal and slideover support for Inertia.js responses.

  This module provides the core data structures and functions for building
  modal and slideover responses in Inertia.js applications. Modals are rendered
  as overlays without full page navigation, providing a smoother user experience.

  ## Custom Headers

  The modal system uses custom HTTP headers to communicate modal state:

  - `X-Inertia-Modal` - Indicates this is a modal response
  - `X-Inertia-Modal-Base-Url` - The base URL for the modal (for redirects)
  - `X-Inertia-Modal-Config` - JSON configuration for modal appearance

  ## Example

      # Build a modal with configuration
      Modal.new("Users/Show", %{user: user})
      |> Modal.base_url("/users")
      |> Modal.size("lg")
      |> Modal.position("center")

      # Build a slideover
      Modal.new("Users/Edit", %{user: user})
      |> Modal.base_url("/users/\#{user.id}")
      |> Modal.slideover(true)
      |> Modal.position("right")
  """

  alias __MODULE__

  @type size :: :sm | :md | :lg | :xl | :full | String.t()
  @type position :: :center | :top | :bottom | :left | :right | String.t()

  @type config :: %{
          optional(:size) => size(),
          optional(:position) => position(),
          optional(:slideover) => boolean(),
          optional(:closeButton) => boolean(),
          optional(:closeExplicitly) => boolean(),
          optional(:maxWidth) => String.t(),
          optional(:paddingClasses) => String.t(),
          optional(:panelClasses) => String.t(),
          optional(:backdropClasses) => String.t()
        }

  @type t :: %__MODULE__{
          component: String.t(),
          props: map(),
          base_url: String.t() | nil,
          config: config()
        }

  defstruct [:component, :props, :base_url, config: %{}]

  # Custom header names
  @modal_header "x-inertia-modal"
  @modal_base_url_header "x-inertia-modal-base-url"
  @modal_config_header "x-inertia-modal-config"

  @doc """
  Returns the custom header name for indicating a modal response.

  ## Example

      iex> NbInertia.Modal.modal_header()
      "x-inertia-modal"
  """
  @spec modal_header() :: String.t()
  def modal_header, do: @modal_header

  @doc """
  Returns the custom header name for the modal base URL.

  ## Example

      iex> NbInertia.Modal.modal_base_url_header()
      "x-inertia-modal-base-url"
  """
  @spec modal_base_url_header() :: String.t()
  def modal_base_url_header, do: @modal_base_url_header

  @doc """
  Returns the custom header name for the modal configuration.

  ## Example

      iex> NbInertia.Modal.modal_config_header()
      "x-inertia-modal-config"
  """
  @spec modal_config_header() :: String.t()
  def modal_config_header, do: @modal_config_header

  @doc """
  Creates a new Modal struct.

  ## Parameters

    - `component` - The Inertia component name to render (e.g., "Users/Show")
    - `props` - The props to pass to the component

  ## Example

      iex> NbInertia.Modal.new("Users/Show", %{user: %{id: 1, name: "Alice"}})
      %NbInertia.Modal{
        component: "Users/Show",
        props: %{user: %{id: 1, name: "Alice"}},
        base_url: nil,
        config: %{}
      }
  """
  @spec new(String.t(), map()) :: t()
  def new(component, props \\ %{}) do
    %Modal{
      component: component,
      props: props,
      base_url: nil,
      config: %{}
    }
  end

  @doc """
  Sets the base URL for the modal.

  The base URL is used when redirecting after modal closure or when the user
  navigates away from the modal. It represents the "background" page that the
  modal overlays.

  ## Parameters

    - `modal` - The Modal struct
    - `url` - The base URL (e.g., "/users" or "/users/123")

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.base_url(modal, "/users")
      %NbInertia.Modal{
        component: "Users/Show",
        props: %{},
        base_url: "/users",
        config: %{}
      }
  """
  @spec base_url(t(), String.t()) :: t()
  def base_url(%Modal{} = modal, url) when is_binary(url) do
    %{modal | base_url: url}
  end

  @doc """
  Sets the base URL using a route helper and parameters.

  This is a convenience function for setting the base URL using Phoenix route
  helpers. It requires the `nb_routes` package to be installed.

  ## Parameters

    - `modal` - The Modal struct
    - `route_helper` - A route helper function or RouteResult struct
    - `params` - Optional parameters for the route (default: [])

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.base_route(modal, &Routes.users_path/3, [:index])
      %NbInertia.Modal{base_url: "/users", ...}

      # With nb_routes rich mode
      iex> NbInertia.Modal.base_route(modal, users_path())
      %NbInertia.Modal{base_url: "/users", ...}
  """
  @spec base_route(t(), function() | map(), list()) :: t()
  # Handle nb_routes RouteResult struct
  def base_route(%Modal{} = modal, %{url: url}, params \\ []) when is_binary(url) do
    _ = params
    base_url(modal, url)
  end

  # Handle traditional route helper function
  def base_route(%Modal{} = _modal, route_helper, params) when is_function(route_helper) do
    _ = params
    # Assume conn and action are provided in params
    # This is a simplified implementation - in practice, you'd need conn from context
    raise "base_route/3 with function requires nb_routes rich mode RouteResult structs"
  end

  @doc """
  Sets the size of the modal.

  ## Parameters

    - `modal` - The Modal struct
    - `size` - The size preset or custom size string

  Valid preset sizes: `:sm`, `:md`, `:lg`, `:xl`, `:full`

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.size(modal, :lg)
      %NbInertia.Modal{config: %{size: :lg}, ...}

      iex> NbInertia.Modal.size(modal, "max-w-4xl")
      %NbInertia.Modal{config: %{size: "max-w-4xl"}, ...}
  """
  @spec size(t(), size()) :: t()
  def size(%Modal{} = modal, size) do
    put_config(modal, :size, size)
  end

  @doc """
  Sets the position of the modal.

  ## Parameters

    - `modal` - The Modal struct
    - `position` - The position preset or custom position string

  Valid preset positions: `:center`, `:top`, `:bottom`, `:left`, `:right`

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.position(modal, :center)
      %NbInertia.Modal{config: %{position: :center}, ...}
  """
  @spec position(t(), position()) :: t()
  def position(%Modal{} = modal, position) do
    put_config(modal, :position, position)
  end

  @doc """
  Configures whether this is a slideover instead of a modal.

  Slideovers typically slide in from the side of the screen rather than
  appearing as a centered overlay.

  ## Parameters

    - `modal` - The Modal struct
    - `enabled` - Boolean indicating if this is a slideover (default: true)

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Edit", %{})
      iex> NbInertia.Modal.slideover(modal)
      %NbInertia.Modal{config: %{slideover: true}, ...}

      iex> NbInertia.Modal.slideover(modal, false)
      %NbInertia.Modal{config: %{slideover: false}, ...}
  """
  @spec slideover(t(), boolean()) :: t()
  def slideover(%Modal{} = modal, enabled \\ true) do
    put_config(modal, :slideover, enabled)
  end

  @doc """
  Configures whether the modal shows a close button.

  ## Parameters

    - `modal` - The Modal struct
    - `enabled` - Boolean indicating if close button should be shown (default: true)

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.close_button(modal, true)
      %NbInertia.Modal{config: %{closeButton: true}, ...}
  """
  @spec close_button(t(), boolean()) :: t()
  def close_button(%Modal{} = modal, enabled \\ true) do
    put_config(modal, :closeButton, enabled)
  end

  @doc """
  Configures whether the modal must be closed explicitly.

  When enabled, clicking the backdrop or pressing ESC won't close the modal.

  ## Parameters

    - `modal` - The Modal struct
    - `enabled` - Boolean indicating if explicit close is required (default: true)

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Delete", %{})
      iex> NbInertia.Modal.close_explicitly(modal, true)
      %NbInertia.Modal{config: %{closeExplicitly: true}, ...}
  """
  @spec close_explicitly(t(), boolean()) :: t()
  def close_explicitly(%Modal{} = modal, enabled \\ true) do
    put_config(modal, :closeExplicitly, enabled)
  end

  @doc """
  Sets custom max-width for the modal.

  ## Parameters

    - `modal` - The Modal struct
    - `max_width` - CSS max-width value (e.g., "800px", "50rem")

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.max_width(modal, "800px")
      %NbInertia.Modal{config: %{maxWidth: "800px"}, ...}
  """
  @spec max_width(t(), String.t()) :: t()
  def max_width(%Modal{} = modal, max_width) when is_binary(max_width) do
    put_config(modal, :maxWidth, max_width)
  end

  @doc """
  Sets custom padding classes for the modal content.

  ## Parameters

    - `modal` - The Modal struct
    - `classes` - CSS class string (e.g., "p-6", "px-4 py-6")

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.padding_classes(modal, "p-8")
      %NbInertia.Modal{config: %{paddingClasses: "p-8"}, ...}
  """
  @spec padding_classes(t(), String.t()) :: t()
  def padding_classes(%Modal{} = modal, classes) when is_binary(classes) do
    put_config(modal, :paddingClasses, classes)
  end

  @doc """
  Sets custom panel classes for the modal container.

  ## Parameters

    - `modal` - The Modal struct
    - `classes` - CSS class string

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.panel_classes(modal, "bg-gray-900 text-white")
      %NbInertia.Modal{config: %{panelClasses: "bg-gray-900 text-white"}, ...}
  """
  @spec panel_classes(t(), String.t()) :: t()
  def panel_classes(%Modal{} = modal, classes) when is_binary(classes) do
    put_config(modal, :panelClasses, classes)
  end

  @doc """
  Sets custom backdrop classes for the modal overlay.

  ## Parameters

    - `modal` - The Modal struct
    - `classes` - CSS class string

  ## Example

      iex> modal = NbInertia.Modal.new("Users/Show", %{})
      iex> NbInertia.Modal.backdrop_classes(modal, "bg-black/75")
      %NbInertia.Modal{config: %{backdropClasses: "bg-black/75"}, ...}
  """
  @spec backdrop_classes(t(), String.t()) :: t()
  def backdrop_classes(%Modal{} = modal, classes) when is_binary(classes) do
    put_config(modal, :backdropClasses, classes)
  end

  # Private helpers

  defp put_config(%Modal{config: config} = modal, key, value) do
    %{modal | config: Map.put(config, key, value)}
  end
end
