defmodule NbInertia.TestEndpoint do
  @moduledoc """
  Minimal Phoenix endpoint for testing nb_inertia.
  """
  use Phoenix.Endpoint, otp_app: :nb_inertia

  @doc false
  def config_change(_changed, _removed), do: :ok
end
