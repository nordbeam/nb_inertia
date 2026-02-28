defmodule NbInertia.Plugs.Flash do
  @moduledoc """
  Deprecated: Flash handling is now built into `NbInertia.Plug`.

  This module is kept for backward compatibility. If your router still
  references `plug NbInertia.Plugs.Flash`, it will work but you should
  remove it — `NbInertia.Plug` handles flash persistence automatically.
  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    # No-op: NbInertia.Plug now handles flash loading and persistence.
    conn
  end
end
