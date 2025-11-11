defmodule NbInertia.LazyProps do
  @moduledoc """
  Helpers for lazy evaluation of large prop collections using Elixir Streams.

  This module provides Stream-based helpers for efficiently handling large datasets
  in Inertia props. By leveraging Elixir's Stream abstraction, you can paginate,
  filter, and transform data lazily without loading everything into memory.

  ## Benefits

  - **Memory Efficient**: Only processes the data you need
  - **Composable**: Chain multiple transformations
  - **Idiomatic**: Uses standard Elixir Stream API
  - **Pagination-Friendly**: Built-in pagination helpers

  ## Usage

  ### Basic Pagination

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, UserSerializer
          prop :page, :integer
          prop :total_pages, :integer
        end

        def index(conn, params) do
          page = Map.get(params, "page", "1") |> String.to_integer()
          page_size = 25

          # Create a lazy stream of users
          users_stream = lazy_paginate(User, params, page_size: page_size)

          # Only fetch the current page
          users = users_stream |> Enum.take(page_size) |> Enum.to_list()
          total = MyApp.Repo.aggregate(User, :count)

          render_inertia(conn, :users_index,
            users: {UserSerializer, users},
            page: page,
            total_pages: div(total + page_size - 1, page_size)
          )
        end
      end

  ### Infinite Scroll

      def index(conn, params) do
        cursor = Map.get(params, "cursor")
        limit = 50

        # Stream with cursor-based pagination
        items_stream = lazy_cursor_paginate(Post, cursor, limit: limit)

        # Take only what we need
        items = items_stream |> Enum.take(limit) |> Enum.to_list()
        next_cursor = items |> List.last() |> then(& &1.id)

        render_inertia(conn, :posts_index,
          items: {PostSerializer, items},
          next_cursor: next_cursor,
          has_more: length(items) == limit
        )
      end

  ### Filtered Streams

      def search(conn, %{"q" => query} = params) do
        page = Map.get(params, "page", "1") |> String.to_integer()

        # Create a lazy filtered stream
        results_stream =
          User
          |> lazy_filter(fn user -> String.contains?(user.name, query) end)
          |> Stream.drop((page - 1) * 25)
          |> Stream.take(25)

        results = Enum.to_list(results_stream)

        render_inertia(conn, :search_results,
          results: {UserSerializer, results},
          query: query,
          page: page
        )
      end
  """

  import Ecto.Query, only: [from: 2]

  @doc """
  Creates a lazy paginated stream from an Ecto queryable.

  The stream fetches data in chunks (pages) as needed, rather than loading
  all records into memory at once.

  ## Parameters

    - `queryable` - An Ecto queryable (schema module or query)
    - `params` - Request params containing pagination info
    - `opts` - Options keyword list

  ## Options

    - `:page_size` - Number of records per page (default: `25`)
    - `:repo` - Ecto repo to use (default: inferred from queryable)
    - `:order_by` - Field to order by (default: `:id`)
    - `:order_direction` - Sort direction (default: `:asc`)

  ## Returns

  A `Stream` that yields records as needed.

  ## Examples

      # Basic usage
      users_stream = lazy_paginate(User, params, page_size: 25)
      users = Enum.take(users_stream, 25)

      # With custom ordering
      posts_stream = lazy_paginate(Post, params,
        page_size: 50,
        order_by: :inserted_at,
        order_direction: :desc
      )

      # Chaining with Stream operations
      recent_users =
        User
        |> lazy_paginate(params, page_size: 100)
        |> Stream.filter(&(&1.inserted_at > ago))
        |> Stream.map(&transform/1)
        |> Enum.take(10)
  """
  @spec lazy_paginate(Ecto.Queryable.t(), map(), keyword()) :: Enumerable.t()
  def lazy_paginate(queryable, params, opts \\ []) do
    page = Map.get(params, "page", "1") |> parse_integer(1)
    page_size = Keyword.get(opts, :page_size, 25)
    order_by = Keyword.get(opts, :order_by, :id)
    order_direction = Keyword.get(opts, :order_direction, :asc)

    repo = Keyword.get(opts, :repo) || infer_repo(queryable)

    # Create a stream that fetches pages on demand
    Stream.resource(
      fn -> {page, 0} end,
      fn {current_page, count} ->
        offset = (current_page - 1) * page_size

        query =
          from(q in queryable,
            order_by: ^[{order_direction, order_by}],
            limit: ^page_size,
            offset: ^offset
          )

        results = repo.all(query)

        if results == [] do
          {:halt, {current_page, count}}
        else
          {results, {current_page + 1, count + length(results)}}
        end
      end,
      fn _ -> :ok end
    )
    |> Stream.flat_map(& &1)
  end

  @doc """
  Creates a cursor-based paginated stream.

  Cursor pagination is more efficient than offset pagination for large datasets
  and provides stable results even when data is being inserted/deleted.

  ## Parameters

    - `queryable` - An Ecto queryable
    - `cursor` - The cursor value (typically an ID) to start from
    - `opts` - Options keyword list

  ## Options

    - `:limit` - Number of records per batch (default: `50`)
    - `:repo` - Ecto repo to use (default: inferred from queryable)
    - `:cursor_field` - Field to use as cursor (default: `:id`)
    - `:order_direction` - Sort direction (default: `:asc`)

  ## Returns

  A `Stream` that yields records using cursor-based pagination.

  ## Examples

      # Start from beginning
      posts_stream = lazy_cursor_paginate(Post, nil, limit: 50)

      # Continue from cursor
      posts_stream = lazy_cursor_paginate(Post, "cursor123", limit: 50)

      # Custom cursor field
      messages_stream = lazy_cursor_paginate(Message, last_timestamp,
        cursor_field: :inserted_at,
        limit: 100
      )
  """
  @spec lazy_cursor_paginate(Ecto.Queryable.t(), term(), keyword()) :: Enumerable.t()
  def lazy_cursor_paginate(queryable, cursor, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    cursor_field = Keyword.get(opts, :cursor_field, :id)
    order_direction = Keyword.get(opts, :order_direction, :asc)
    repo = Keyword.get(opts, :repo) || infer_repo(queryable)

    Stream.resource(
      fn -> cursor end,
      fn current_cursor ->
        query =
          if current_cursor do
            if order_direction == :asc do
              from(q in queryable,
                where: field(q, ^cursor_field) > ^current_cursor,
                order_by: ^[{order_direction, cursor_field}],
                limit: ^limit
              )
            else
              from(q in queryable,
                where: field(q, ^cursor_field) < ^current_cursor,
                order_by: ^[{order_direction, cursor_field}],
                limit: ^limit
              )
            end
          else
            from(q in queryable,
              order_by: ^[{order_direction, cursor_field}],
              limit: ^limit
            )
          end

        results = repo.all(query)

        if results == [] do
          {:halt, nil}
        else
          next_cursor = results |> List.last() |> Map.get(cursor_field)
          {results, next_cursor}
        end
      end,
      fn _ -> :ok end
    )
    |> Stream.flat_map(& &1)
  end

  @doc """
  Creates a lazy filtered stream.

  Applies a filter function lazily as elements are consumed from the stream.

  ## Parameters

    - `queryable_or_stream` - An Ecto queryable or existing stream
    - `filter_fn` - A function that returns `true` to keep an element

  ## Returns

  A `Stream` with the filter applied.

  ## Examples

      # Filter users
      active_users =
        User
        |> lazy_filter(&(&1.active))
        |> Enum.take(10)

      # Chain filters
      premium_recent_users =
        User
        |> lazy_filter(&(&1.premium))
        |> lazy_filter(&(&1.inserted_at > cutoff_date))
        |> Enum.to_list()
  """
  @spec lazy_filter(Ecto.Queryable.t() | Enumerable.t(), (term() -> boolean())) ::
          Enumerable.t()
  def lazy_filter(queryable_or_stream, filter_fn) when is_function(filter_fn, 1) do
    stream =
      if is_struct(queryable_or_stream, Ecto.Query) or is_atom(queryable_or_stream) do
        # Convert queryable to stream
        repo = infer_repo(queryable_or_stream)
        repo.stream(queryable_or_stream)
      else
        queryable_or_stream
      end

    Stream.filter(stream, filter_fn)
  end

  @doc """
  Creates a lazy mapped stream with transformation function.

  ## Parameters

    - `stream` - An enumerable or stream
    - `mapper_fn` - A function to transform each element

  ## Returns

  A `Stream` with the transformation applied.

  ## Examples

      users_with_stats =
        User
        |> lazy_paginate(params)
        |> lazy_map(&add_stats/1)
        |> Enum.take(25)
  """
  @spec lazy_map(Enumerable.t(), (term() -> term())) :: Enumerable.t()
  def lazy_map(stream, mapper_fn) when is_function(mapper_fn, 1) do
    Stream.map(stream, mapper_fn)
  end

  @doc """
  Converts a stream to a paginated result with metadata.

  This is a convenience function that materializes a page of results
  and includes helpful pagination metadata.

  ## Parameters

    - `stream` - The stream to paginate
    - `page` - Current page number (1-indexed)
    - `page_size` - Number of items per page

  ## Returns

  A map containing:
  - `:entries` - The page of results
  - `:page_number` - Current page
  - `:page_size` - Items per page
  - `:has_next` - Whether there's a next page
  - `:has_prev` - Whether there's a previous page

  ## Examples

      page_result = stream |> paginate_stream(page, 25)

      render_inertia(conn, :index,
        items: {ItemSerializer, page_result.entries},
        page: page_result.page_number,
        has_next: page_result.has_next,
        has_prev: page_result.has_prev
      )
  """
  @spec paginate_stream(Enumerable.t(), pos_integer(), pos_integer()) :: map()
  def paginate_stream(stream, page, page_size) do
    # Take one extra to check if there's a next page
    entries =
      stream
      |> Stream.drop((page - 1) * page_size)
      |> Enum.take(page_size + 1)

    has_next = length(entries) > page_size
    actual_entries = if has_next, do: Enum.take(entries, page_size), else: entries

    %{
      entries: actual_entries,
      page_number: page,
      page_size: page_size,
      has_next: has_next,
      has_prev: page > 1
    }
  end

  ## Private Helpers

  # Infer the repo from the queryable
  defp infer_repo(queryable) do
    # Try to get repo from the schema module
    schema_module =
      cond do
        is_atom(queryable) -> queryable
        is_struct(queryable, Ecto.Query) -> queryable.from.source |> elem(1)
        true -> nil
      end

    if schema_module && function_exported?(schema_module, :__schema__, 1) do
      # Use the application's default repo
      # This could be made configurable
      case Application.get_env(:nb_inertia, :repo) do
        nil ->
          # Fallback: try to infer from application
          app = Application.get_application(schema_module)

          app
          |> Application.get_env(:ecto_repos, [])
          |> List.first()

        repo ->
          repo
      end
    else
      raise ArgumentError, """
      Could not infer repo for #{inspect(queryable)}.

      Please specify the repo explicitly:

          lazy_paginate(User, params, repo: MyApp.Repo)

      Or configure a default repo:

          config :nb_inertia,
            repo: MyApp.Repo
      """
    end
  end

  # Parse integer with default
  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_integer(value, _default) when is_integer(value), do: value
  defp parse_integer(_, default), do: default
end
