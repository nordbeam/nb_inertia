defmodule NbInertia.ComponentNaming do
  @moduledoc """
  Utilities for inferring Inertia component names from atom-based page references.

  Converts snake_case atoms like `:users_index` into PascalCase component paths
  like `"Users/Index"` following common conventions.
  """

  @standard_actions ~w(index show new edit create update delete)a
  @namespace_prefixes ~w(admin api public internal)a

  @doc """
  Infers an Inertia component name from a page atom.

  ## Examples

      iex> NbInertia.ComponentNaming.infer(:users_index)
      "Users/Index"

      iex> NbInertia.ComponentNaming.infer(:users_show)
      "Users/Show"

      iex> NbInertia.ComponentNaming.infer(:admin_dashboard)
      "Admin/Dashboard"

      iex> NbInertia.ComponentNaming.infer(:admin_users_index)
      "Admin/Users/Index"

      iex> NbInertia.ComponentNaming.infer(:dashboard)
      "Dashboard"

      iex> NbInertia.ComponentNaming.infer(:user_profile)
      "UserProfile"
  """
  @spec infer(atom()) :: String.t()
  def infer(page_atom) when is_atom(page_atom) do
    page_atom
    |> Atom.to_string()
    |> String.split("_")
    |> parse_parts([])
    |> build_component_path()
  end

  # Parse parts and identify namespaces and actions
  defp parse_parts([], acc), do: Enum.reverse(acc)

  defp parse_parts([part | rest], acc) do
    cond do
      # Check if this is a namespace prefix at the start
      part in Enum.map(@namespace_prefixes, &Atom.to_string/1) and acc == [] ->
        parse_parts(rest, [{:namespace, part} | acc])

      # Check if this is a namespace prefix followed by more parts
      part in Enum.map(@namespace_prefixes, &Atom.to_string/1) and length(rest) > 0 ->
        parse_parts(rest, [{:namespace, part} | acc])

      # Check if this is a standard action at the end
      String.to_existing_atom(part) in @standard_actions and rest == [] ->
        parse_parts(rest, [{:action, part} | acc])

      # Regular part
      true ->
        parse_parts(rest, [{:part, part} | acc])
    end
  rescue
    # If String.to_existing_atom fails, treat as regular part
    ArgumentError ->
      parse_parts(rest, [{:part, part} | acc])
  end

  # Build the component path from parsed parts
  defp build_component_path(parts) do
    {namespaces, rest} = Enum.split_while(parts, fn {type, _} -> type == :namespace end)

    {actions, middle} =
      rest |> Enum.reverse() |> Enum.split_while(fn {type, _} -> type == :action end)

    resource_parts = Enum.reverse(middle)

    namespace_path =
      namespaces
      |> Enum.map(fn {:namespace, name} -> camelize(name) end)
      |> Enum.join("/")

    resource_path =
      resource_parts
      |> Enum.map(fn {:part, name} -> camelize(name) end)
      |> Enum.join("")

    action_path =
      actions
      |> Enum.map(fn {:action, name} -> camelize(name) end)
      |> Enum.join("")

    # Build final path
    path_parts =
      [namespace_path, resource_path, action_path]
      |> Enum.reject(&(&1 == ""))

    case path_parts do
      # Single word (e.g., :dashboard)
      [single] ->
        single

      # Namespace with resource and action (e.g., Admin/Users/Index)
      [namespace, resource, action] ->
        "#{namespace}/#{resource}/#{action}"

      # Two parts - could be Resource/Action or Namespace/Resource
      [part1, part2] ->
        "#{part1}/#{part2}"

      # Fallback for more complex paths
      _ ->
        Enum.join(path_parts, "/")
    end
  end

  # Convert snake_case string to PascalCase
  defp camelize(string) do
    string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end
end
