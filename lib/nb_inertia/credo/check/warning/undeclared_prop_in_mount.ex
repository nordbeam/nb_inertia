# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.UndeclaredPropInMount do
    @moduledoc """
    Warns when `mount/2` returns map keys that are not declared as props
    in the Page module.

    This is a static analysis check that only works for literal map returns
    in `mount/2`. Dynamic maps or maps built with variables cannot be checked.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list

          def mount(_conn, _params) do
            %{users: list_users(), total_count: count_users()}  # :total_count not declared!
          end
        end

    Declare all returned props:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list
          prop :total_count, :integer

          def mount(_conn, _params) do
            %{users: list_users(), total_count: count_users()}
          end
        end

    """
    use Credo.Check,
      id: "EX5032",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        All keys returned from `mount/2` in a Page module should be declared
        as props using the `prop` macro.

        Undeclared props won't be type-checked and won't appear in generated
        TypeScript types. Add `prop :name, :type` declarations for all keys
        returned from `mount/2`.

        Note: This check only analyzes literal map returns. Dynamic maps
        constructed with variables or function calls cannot be statically checked.
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
        declared_props: MapSet.new(),
        mount_map_keys: [],
        in_mount: false
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

    # Track `prop :name, ...`
    defp traverse({:prop, _meta, [prop_name | _]} = ast, state)
         when is_atom(prop_name) do
      {ast, %{state | declared_props: MapSet.put(state.declared_props, prop_name)}}
    end

    # Track `def mount(_, _)` — look for map literal returns
    defp traverse({:def, _meta, [{:mount, _, args}, body]} = ast, state)
         when is_list(args) and length(args) == 2 do
      # Extract map keys from the function body
      mount_keys = extract_map_keys_from_body(body)

      new_mount_keys = state.mount_map_keys ++ mount_keys
      {ast, %{state | mount_map_keys: new_mount_keys}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp check_final(state) do
      if state.has_use_page and state.mount_map_keys != [] do
        Enum.reduce(state.mount_map_keys, [], fn {key, line}, issues ->
          if MapSet.member?(state.declared_props, key) do
            issues
          else
            issue = issue_for(state.issue_meta, line, key)
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
    defp find_map_keys({:%{}, meta, pairs} = ast, acc) when is_list(pairs) do
      line = meta[:line] || 0

      new_keys =
        Enum.flat_map(pairs, fn
          {key, _value} when is_atom(key) -> [{key, line}]
          _ -> []
        end)

      {ast, acc ++ new_keys}
    end

    defp find_map_keys(ast, acc), do: {ast, acc}

    defp issue_for(issue_meta, line_no, prop_name) do
      format_issue(
        issue_meta,
        message:
          "Key `:#{prop_name}` returned from `mount/2` is not declared as a prop. Add `prop :#{prop_name}, <type>` to the module.",
        trigger: "mount",
        line_no: line_no
      )
    end
  end
end
