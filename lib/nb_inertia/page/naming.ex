defmodule NbInertia.Page.Naming do
  @moduledoc """
  Module-based component name derivation for `NbInertia.Page` modules.

  Converts Elixir module names into Inertia component paths by:
  1. Splitting the module name into segments
  2. Dropping segments up to and including the web module (`*Web`)
  3. Stripping the `Page` suffix from segments ending in `Page`
  4. Joining remaining segments with `/`

  ## Examples

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.UsersPage.Index)
      "Users/Index"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.Admin.UsersPage.Edit)
      "Admin/Users/Edit"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.DashboardPage)
      "Dashboard"
  """

  @doc """
  Derives an Inertia component name from a Page module name.

  ## Algorithm

  1. Split the module name into segments (e.g., `["MyAppWeb", "UsersPage", "Index"]`)
  2. Drop segments up to and including any segment ending in `Web`
  3. Strip the `Page` suffix from segments ending in `Page`
  4. Join remaining segments with `/`

  ## Examples

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.UsersPage.Index)
      "Users/Index"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.UsersPage.Show)
      "Users/Show"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.DashboardPage)
      "Dashboard"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.Admin.UsersPage.Edit)
      "Admin/Users/Edit"

      iex> NbInertia.Page.Naming.derive_component(MyApp.SomePage)
      "Some"

      iex> NbInertia.Page.Naming.derive_component(MyAppWeb.Settings)
      "Settings"
  """
  @spec derive_component(module()) :: String.t()
  def derive_component(module) when is_atom(module) do
    module
    |> Module.split()
    |> drop_web_prefix()
    |> strip_page_suffixes()
    |> Enum.join("/")
    |> case do
      "" -> raise ArgumentError, "Could not derive component name from #{inspect(module)}"
      name -> name
    end
  end

  # Drop all segments up to and including any segment ending in "Web"
  defp drop_web_prefix(segments) do
    case Enum.find_index(segments, &String.ends_with?(&1, "Web")) do
      nil -> segments
      idx -> Enum.drop(segments, idx + 1)
    end
  end

  # Strip "Page" suffix from segments ending in "Page" (but not just "Page" alone)
  defp strip_page_suffixes(segments) do
    Enum.map(segments, fn segment ->
      case segment do
        "Page" ->
          "Page"

        _ ->
          if String.ends_with?(segment, "Page") do
            String.replace_suffix(segment, "Page", "")
          else
            segment
          end
      end
    end)
  end
end
