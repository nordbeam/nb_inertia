# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.UnusedPropInMount do
    @moduledoc """
    Warns when a declared prop is not returned from `mount/2` and does not
    have a `from:` or `default:` option that would provide the value automatically.

    This is a static analysis check that only works for literal map returns
    in `mount/2`. If `mount/2` uses conn pipeline (e.g., `props(%{...})`),
    the map keys inside `props/2` are analyzed.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list
          prop :total_count, :integer  # Never returned from mount!

          def mount(_conn, _params) do
            %{users: list_users()}
          end
        end

    Either return it from mount:

        def mount(_conn, _params) do
          %{users: list_users(), total_count: count_users()}
        end

    Or use a default value:

        prop :total_count, :integer, default: 0

    """
    use Credo.Check,
      id: "EX5033",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        Props declared in a Page module should be returned from `mount/2` unless
        they have a `from:` or `default:` option.

        Unused props indicate either:
        - A prop that should be returned from `mount/2`
        - A prop that needs a `default:` option
        - A stale prop declaration that should be removed

        Note: This check only analyzes literal map returns and `props(%{...})`
        calls. Dynamic map construction cannot be statically checked.
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      initial_state = %{
        issue_meta: issue_meta,
        issues: [],
        has_use_page: false,
        # {name, line, has_from_or_default}
        declared_props: [],
        mount_map_keys: MapSet.new(),
        has_mount: false
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      check_final(final_state)
    end

    # Track `use NbInertia.Page`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_page: true}}
    end

    # Track `prop :name, type, opts` (3 args with keyword opts)
    defp traverse({:prop, meta, [prop_name, _type, opts]} = ast, state)
         when is_atom(prop_name) and is_list(opts) do
      has_from_or_default =
        Keyword.has_key?(opts, :from) or Keyword.has_key?(opts, :default) or
          Keyword.has_key?(opts, :defer)

      prop_info = {prop_name, meta[:line], has_from_or_default}
      {ast, %{state | declared_props: [prop_info | state.declared_props]}}
    end

    # Track `prop :name, type` (2 args, no special opts)
    defp traverse({:prop, meta, [prop_name, _type]} = ast, state)
         when is_atom(prop_name) do
      prop_info = {prop_name, meta[:line], false}
      {ast, %{state | declared_props: [prop_info | state.declared_props]}}
    end

    # Track `def mount(_, _)` — look for map literal returns
    defp traverse({:def, _meta, [{:mount, _, args}, body]} = ast, state)
         when is_list(args) and length(args) == 2 do
      mount_keys = extract_map_keys_from_body(body)
      new_keys = Enum.reduce(mount_keys, state.mount_map_keys, &MapSet.put(&2, &1))
      {ast, %{state | mount_map_keys: new_keys, has_mount: true}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp check_final(state) do
      # Only check if we have a Page module with mount/2 and literal map keys
      if state.has_use_page and state.has_mount and MapSet.size(state.mount_map_keys) > 0 do
        state.declared_props
        |> Enum.reverse()
        |> Enum.reduce([], fn {prop_name, line, has_from_or_default}, issues ->
          if has_from_or_default or MapSet.member?(state.mount_map_keys, prop_name) do
            issues
          else
            issue = issue_for(state.issue_meta, line, prop_name)
            [issue | issues]
          end
        end)
        |> Enum.reverse()
      else
        []
      end
    end

    # Extract atom keys from map literals in the function body
    defp extract_map_keys_from_body(body) do
      {_ast, keys} = Macro.prewalk(body, [], &find_map_keys/2)
      keys
    end

    # Match `%{key: value, ...}` map literals
    defp find_map_keys({:%{}, _meta, pairs} = ast, acc) when is_list(pairs) do
      new_keys =
        Enum.flat_map(pairs, fn
          {key, _value} when is_atom(key) -> [key]
          _ -> []
        end)

      {ast, acc ++ new_keys}
    end

    defp find_map_keys(ast, acc), do: {ast, acc}

    defp issue_for(issue_meta, line_no, prop_name) do
      format_issue(
        issue_meta,
        message:
          "Prop `:#{prop_name}` is declared but not returned from `mount/2`. Either return it from `mount/2`, add a `default:` option, or remove the declaration.",
        trigger: "prop",
        line_no: line_no
      )
    end
  end
end
