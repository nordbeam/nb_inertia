defmodule Inertia.SSR do
  @moduledoc """
  Shim module that overrides the original Inertia.SSR to use NbInertia.SSR.

  This module provides the same interface as the original Inertia.SSR but
  delegates all calls to NbInertia.SSR, which uses DenoRider instead of NodeJS.

  Because nb_inertia is loaded after inertia in the dependency tree and this
  file will compile, it will override the original Inertia.SSR module.
  """

  @doc """
  Renders an Inertia page using NbInertia's SSR implementation.

  This function maintains API compatibility with the original Inertia.SSR.call/1.

  ## Parameters

    * `page` - The Inertia page data (component name, props, etc.)

  ## Returns

    * `{:ok, %{"head" => head, "body" => body}}` - The rendered HTML
    * `{:error, reason}` - If rendering fails
  """
  defdelegate call(page), to: NbInertia.SSR
end
