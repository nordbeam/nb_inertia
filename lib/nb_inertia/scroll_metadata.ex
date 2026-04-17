defmodule NbInertia.ScrollMetadata do
  @moduledoc false

  @containers [
    [],
    [:meta],
    ["meta"],
    [:metadata],
    ["metadata"],
    [:pagination],
    ["pagination"],
    [:meta, :pagination],
    ["meta", "pagination"],
    [:metadata, :pagination],
    ["metadata", "pagination"]
  ]

  @spec to_scroll_metadata(any()) :: %{
          page_name: String.t(),
          current_page: integer() | String.t() | nil,
          previous_page: integer() | String.t() | nil,
          next_page: integer() | String.t() | nil
        }
  def to_scroll_metadata(data) do
    current_page = current_page(data)

    %{
      page_name: page_name(data),
      current_page: current_page,
      previous_page: previous_page(data, current_page),
      next_page: next_page(data, current_page)
    }
  end

  defp page_name(data) do
    case find_metadata_value(data, [:page_name, "page_name", :pageName, "pageName"]) do
      {:ok, value} when not is_nil(value) -> to_string(value)
      _ -> "page"
    end
  end

  defp current_page(data) do
    case find_metadata_value(data, [
           :current_page,
           "current_page",
           :currentPage,
           "currentPage",
           :page_number,
           "page_number",
           :pageNumber,
           "pageNumber",
           :page,
           "page"
         ]) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp previous_page(data, current_page) do
    case find_metadata_value(data, [
           :previous_page,
           "previous_page",
           :prev_page,
           "prev_page",
           :previousPage,
           "previousPage",
           :prevPage,
           "prevPage"
         ]) do
      {:ok, value} ->
        value

      :error ->
        case find_metadata_value(data, [
               :has_previous_page,
               "has_previous_page",
               :hasPreviousPage,
               "hasPreviousPage",
               :has_previous,
               "has_previous",
               :hasPrevious,
               "hasPrevious",
               :has_prev,
               "has_prev",
               :hasPrev,
               "hasPrev"
             ]) do
          {:ok, true} -> previous_page_from_current(current_page)
          {:ok, false} -> nil
          :error -> previous_page_from_current(current_page)
        end
    end
  end

  defp next_page(data, current_page) do
    case find_metadata_value(data, [
           :next_page,
           "next_page",
           :nextPage,
           "nextPage"
         ]) do
      {:ok, value} ->
        value

      :error ->
        case find_metadata_value(data, [
               :total_pages,
               "total_pages",
               :totalPages,
               "totalPages",
               :last_page,
               "last_page",
               :lastPage,
               "lastPage"
             ]) do
          {:ok, total_pages} ->
            next_page_from_total_pages(current_page, total_pages)

          :error ->
            case find_metadata_value(data, [
                   :has_next_page,
                   "has_next_page",
                   :hasNextPage,
                   "hasNextPage",
                   :has_next,
                   "has_next",
                   :hasNext,
                   "hasNext",
                   :has_more_pages,
                   "has_more_pages",
                   :hasMorePages,
                   "hasMorePages",
                   :has_more,
                   "has_more",
                   :hasMore,
                   "hasMore"
                 ]) do
              {:ok, true} -> next_page_from_current(current_page)
              {:ok, false} -> nil
              :error -> nil
            end
        end
    end
  end

  defp previous_page_from_current(current_page)
       when is_integer(current_page) and current_page > 1,
       do: current_page - 1

  defp previous_page_from_current(_current_page), do: nil

  defp next_page_from_current(current_page) when is_integer(current_page), do: current_page + 1
  defp next_page_from_current(_current_page), do: nil

  defp next_page_from_total_pages(current_page, total_pages)
       when is_integer(current_page) and is_integer(total_pages) and current_page < total_pages,
       do: current_page + 1

  defp next_page_from_total_pages(_current_page, _total_pages), do: nil

  defp find_metadata_value(data, keys) do
    paths =
      for container <- @containers,
          key <- keys do
        container ++ [key]
      end

    Enum.reduce_while(paths, :error, fn path, _acc ->
      case fetch_path(data, path) do
        {:ok, value} -> {:halt, {:ok, value}}
        :error -> {:cont, :error}
      end
    end)
  end

  defp fetch_path(data, [key]), do: fetch_key(data, key)

  defp fetch_path(data, [key | rest]) do
    with {:ok, value} <- fetch_key(data, key) do
      fetch_path(value, rest)
    end
  end

  defp fetch_path(_data, []), do: :error

  defp fetch_key(data, key) when is_map(data) do
    if Map.has_key?(data, key) do
      {:ok, Map.get(data, key)}
    else
      :error
    end
  end

  defp fetch_key(data, key) when is_list(data) and is_atom(key) do
    if Keyword.keyword?(data) and Keyword.has_key?(data, key) do
      {:ok, Keyword.get(data, key)}
    else
      :error
    end
  end

  defp fetch_key(_data, _key), do: :error
end
