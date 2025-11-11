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
    atom_string = Atom.to_string(page_atom)

    # Sanitize: keep only alphanumeric characters and underscores
    sanitized = String.replace(atom_string, ~r/[^a-zA-Z0-9_]/, "")

    # Handle edge cases: empty atoms or atoms that are just underscores
    if String.trim(sanitized, "_") == "" do
      # Return a valid default for empty/underscore-only atoms
      "Index"
    else
      sanitized
      |> String.split("_")
      # Remove empty strings from consecutive underscores
      |> Enum.reject(&(&1 == ""))
      |> parse_parts([])
      |> build_component_path()
    end
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
    # Handle empty parts list
    if parts == [] do
      "Index"
    else
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
        # Empty path parts - fallback to default
        [] ->
          "Index"

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
  end

  # Convert snake_case string to PascalCase
  defp camelize(string) do
    if string == "" do
      ""
    else
      result =
        string
        |> String.split("_")
        # Remove empty strings
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&String.capitalize/1)
        |> Enum.join("")

      # Ensure the result starts with an uppercase letter (not a digit)
      if result != "" and not String.match?(result, ~r/^[A-Z]/) do
        "Page#{result}"
      else
        result
      end
    end
  end
end
