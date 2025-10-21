defmodule NbInertia.ParamsConverter do
  @moduledoc """
  Plug to convert incoming camelCase parameter keys to snake_case.

  This plug automatically converts all camelCase keys in `conn.params` and `conn.body_params`
  to snake_case, making them compatible with Ecto changesets and Phoenix conventions.

  ## Usage

  Add this plug to your router pipeline:

      pipeline :inertia_app do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug NbInertia.ParamsConverter  # Add this line
        plug Inertia.Plug
      end

  ## Configuration

  Enable/disable via config:

      config :nb_inertia, snake_case_params: true  # default

  ## Examples

      # Frontend sends:
      %{
        "primaryProductId" => 123,
        "userName" => "John",
        "isActive" => true
      }

      # Controller receives:
      %{
        "primary_product_id" => 123,
        "user_name" => "John",
        "is_active" => true
      }

  ## Notes

  - Only converts string keys (atom keys are preserved)
  - Preserves nested map and list structures
  - Skips conversion if `snake_case_params: false` in config
  - Works seamlessly with `camelize_props: true` for bidirectional conversion
  """

  alias NbInertia.Config

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    if Config.snake_case_params() do
      convert_params(conn)
    else
      conn
    end
  end

  defp convert_params(conn) do
    conn
    |> Map.update!(:params, &deep_convert_keys/1)
    |> Map.update!(:body_params, &deep_convert_keys/1)
  end

  @doc false
  def deep_convert_keys(value) when is_map(value) do
    Map.new(value, fn {key, val} ->
      {convert_key(key), deep_convert_keys(val)}
    end)
  end

  def deep_convert_keys(value) when is_list(value) do
    Enum.map(value, &deep_convert_keys/1)
  end

  def deep_convert_keys(value), do: value

  defp convert_key(key) when is_binary(key) do
    Macro.underscore(key)
  end

  defp convert_key(key), do: key
end
