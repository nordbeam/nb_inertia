defmodule NbInertia.DeepMerge do
  @moduledoc """
  Deep merging utilities for combining nested maps and keyword lists.

  Used for merging shared props with page-specific props when deep merging is enabled.

  ## Examples

      iex> left = %{a: %{b: 1, c: 2}}
      iex> right = %{a: %{b: 3, d: 4}}
      iex> NbInertia.DeepMerge.deep_merge(left, right)
      %{a: %{b: 3, c: 2, d: 4}}

      iex> left = %{nested: %{count: 10, items: []}}
      iex> right = %{nested: %{count: 20}}
      iex> NbInertia.DeepMerge.deep_merge(left, right)
      %{nested: %{count: 20, items: []}}
  """

  @doc """
  Recursively merges two maps, combining nested structures.

  When both values for the same key are maps, they are recursively merged.
  Otherwise, the right value takes precedence (same as `Map.merge/2`).

  ## Parameters

    * `left` - The base map (lower priority)
    * `right` - The overriding map (higher priority)

  ## Examples

      iex> deep_merge(%{a: 1, b: %{c: 2}}, %{b: %{d: 3}})
      %{a: 1, b: %{c: 2, d: 3}}

      iex> deep_merge(%{settings: %{theme: "dark"}}, %{settings: %{notifications: true}})
      %{settings: %{theme: "dark", notifications: true}}

      iex> deep_merge(%{a: %{b: 1}}, [a: %{c: 2}])
      %{a: %{b: 1, c: 2}}
  """
  @spec deep_merge(map(), map()) :: map()
  @spec deep_merge(map(), keyword()) :: map()
  def deep_merge(left, right)

  def deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  def deep_merge(left, right) when is_map(left) and is_list(right) do
    deep_merge(left, Enum.into(right, %{}))
  end

  def deep_merge(_left, right), do: right

  @doc """
  Merges props from multiple sources with deep merging enabled.

  Takes a list of prop sources (keyword lists or maps) and deep merges them
  from left to right, with later sources taking precedence.

  ## Examples

      iex> sources = [
      ...>   [user: %{name: "Alice", age: 30}],
      ...>   [user: %{age: 31, email: "alice@example.com"}],
      ...>   [user: %{active: true}]
      ...> ]
      iex> deep_merge_all(sources)
      %{user: %{name: "Alice", age: 31, email: "alice@example.com", active: true}}
  """
  @spec deep_merge_all([map() | keyword()]) :: map()
  def deep_merge_all(sources) when is_list(sources) do
    Enum.reduce(sources, %{}, fn source, acc ->
      source_map = if is_list(source), do: Enum.into(source, %{}), else: source
      deep_merge(acc, source_map)
    end)
  end
end
