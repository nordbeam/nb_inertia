defmodule NbInertia.HTML do
  @moduledoc """
  HTML components for NbInertia views with proper SSR support.

  This module provides templates for rendering Inertia pages with server-side
  rendering, ensuring that both the SSR-rendered HTML and the page data
  (including props) are properly embedded in the response.
  """

  use Phoenix.Component

  @doc false
  def inertia_ssr(assigns) do
    ~H"""
    <div id="app" data-page={json_library().encode!(@page)}>
      {Phoenix.HTML.raw(@body)}
    </div>
    """
  end

  defp json_library do
    Phoenix.json_library()
  end
end
