defmodule NbInertia.SSR.RenderError do
  @moduledoc """
  Exception raised when SSR rendering fails.
  """
  defexception [:message]
end
