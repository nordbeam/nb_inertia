defmodule Mix.Tasks.NbInertia.MigrateToPages do
  @shortdoc "Generates Page module scaffolds from an existing controller's inertia_page declarations."

  @moduledoc """
  Generates Page module scaffolds from an existing controller's `inertia_page` declarations.

  This task parses a controller module's source code, finds `inertia_page` blocks,
  and prints suggested Page module files and router changes to help you migrate
  from the controller-based pattern to Page modules.

  The output is informational only — no files are written automatically.
  Review the suggestions and create the files yourself, or copy-paste the output.

  ## Usage

      mix nb_inertia.migrate_to_pages --controller MyAppWeb.UserController

  ## Options

      --controller MODULE   The fully qualified controller module name (required)
      --output-dir DIR      Output directory for generated files (default: prints to stdout)
      --write               Actually write files instead of printing (use with caution)

  ## Examples

      # Print migration plan for a controller
      mix nb_inertia.migrate_to_pages --controller MyAppWeb.UserController

      # Write generated Page modules to disk
      mix nb_inertia.migrate_to_pages --controller MyAppWeb.UserController --write
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          controller: :string,
          output_dir: :string,
          write: :boolean
        ]
      )

    controller_name = opts[:controller]
    write? = opts[:write] || false

    unless controller_name do
      Mix.raise("""
      Missing required --controller option.

      Usage:
          mix nb_inertia.migrate_to_pages --controller MyAppWeb.UserController
      """)
    end

    controller_module = Module.concat([controller_name])

    # Find the source file for the controller
    source_path = find_source_file(controller_module)

    unless source_path do
      Mix.raise("""
      Could not find source file for #{controller_name}.

      Make sure the module exists and the file follows standard Elixir conventions:
          lib/#{controller_name |> Macro.underscore() |> String.replace(".", "/")}.ex
      """)
    end

    Mix.shell().info("Analyzing #{controller_name} at #{source_path}...\n")

    source = File.read!(source_path)
    inertia_pages = extract_inertia_pages(source)

    if Enum.empty?(inertia_pages) do
      Mix.shell().info("""
      No `inertia_page` declarations found in #{controller_name}.

      This controller may already use Page modules, or it may use
      render_inertia without explicit page declarations.
      """)
    else
      web_module = infer_web_module(controller_name)
      resource_name = infer_resource_name(controller_name)

      Mix.shell().info(
        "Found #{length(inertia_pages)} inertia_page declaration(s): #{Enum.map_join(inertia_pages, ", ", & &1.name)}\n"
      )

      # Generate page modules
      page_modules =
        Enum.map(inertia_pages, fn page ->
          generate_page_module(page, web_module, resource_name)
        end)

      # Generate router changes
      router_changes = generate_router_changes(inertia_pages, web_module, resource_name)

      # Output
      Mix.shell().info(separator("Generated Page Modules"))

      Enum.each(page_modules, fn {path, content} ->
        Mix.shell().info("#{separator(path)}\n")
        Mix.shell().info(content)
        Mix.shell().info("")

        if write? do
          dir = Path.dirname(path)
          File.mkdir_p!(dir)
          File.write!(path, content)
          Mix.shell().info("  -> Written to #{path}")
        end
      end)

      Mix.shell().info(separator("Suggested Router Changes"))
      Mix.shell().info(router_changes)

      Mix.shell().info(separator("Migration Checklist"))

      Mix.shell().info("""
      1. Create the Page module files shown above
         (or run with --write to generate them automatically)

      2. Update your router:
         - Remove old controller routes
         - Add `import NbInertia.Router` if not already present
         - Add the suggested inertia routes

      3. Remove the old controller file:
         #{source_path}

      4. Run `mix compile` to verify everything works

      5. Existing frontend components (assets/js/pages/) remain unchanged.
         Page modules use the same component naming convention.
      """)
    end
  end

  # ── Source file discovery ──────────────────────────────────────────────────

  defp find_source_file(module) do
    # Try standard lib path
    underscore_path =
      module
      |> inspect()
      |> Macro.underscore()
      |> String.replace(".", "/")

    path = "lib/#{underscore_path}.ex"

    if File.exists?(path) do
      path
    else
      # Try to find by module name in lib directory
      find_module_file_in_lib(module)
    end
  end

  defp find_module_file_in_lib(module) do
    module_string = "defmodule #{inspect(module)}"

    Path.wildcard("lib/**/*.ex")
    |> Enum.find(fn path ->
      content = File.read!(path)
      String.contains?(content, module_string)
    end)
  end

  # ── Inertia page extraction ────────────────────────────────────────────────

  defp extract_inertia_pages(source) do
    # Parse the source to AST
    case Code.string_to_quoted(source) do
      {:ok, ast} ->
        find_inertia_page_blocks(ast)

      {:error, _} ->
        Mix.shell().error(
          "Warning: Could not parse source file. Falling back to regex extraction."
        )

        extract_inertia_pages_regex(source)
    end
  end

  defp find_inertia_page_blocks(ast) do
    {_, pages} = Macro.prewalk(ast, [], &collect_inertia_pages/2)
    Enum.reverse(pages)
  end

  defp collect_inertia_pages({:inertia_page, _meta, [name, [do: body]]} = node, acc) do
    props = extract_props_from_block(body)

    page = %{
      name: name,
      props: props,
      raw_block: Macro.to_string(body)
    }

    {node, [page | acc]}
  end

  defp collect_inertia_pages(node, acc), do: {node, acc}

  defp extract_props_from_block({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_single_prop/1)
  end

  defp extract_props_from_block(statement) do
    extract_single_prop(statement)
  end

  defp extract_single_prop({:prop, _meta, args}) do
    case args do
      [name, type] ->
        [%{name: name, type: Macro.to_string(type), opts: []}]

      [name, type, opts] when is_list(opts) ->
        [%{name: name, type: Macro.to_string(type), opts: opts}]

      [name] ->
        [%{name: name, type: ":any", opts: []}]

      _ ->
        []
    end
  end

  defp extract_single_prop(_), do: []

  # Fallback regex extraction for unparseable sources
  defp extract_inertia_pages_regex(source) do
    ~r/inertia_page\s+:(\w+)\s+do\s+(.*?)\s+end/ms
    |> Regex.scan(source)
    |> Enum.map(fn [_full, name, body] ->
      props =
        ~r/prop\s+:(\w+),\s+(.+?)$/m
        |> Regex.scan(body)
        |> Enum.map(fn
          [_full, prop_name, rest] ->
            %{name: String.to_atom(prop_name), type: String.trim(rest), opts: []}
        end)

      %{
        name: String.to_atom(name),
        props: props,
        raw_block: body
      }
    end)
  end

  # ── Module generation ──────────────────────────────────────────────────────

  defp generate_page_module(page, web_module, resource_name) do
    action_name = infer_action_name(page.name, resource_name)

    page_module_name =
      "#{web_module}.#{resource_page_name(resource_name)}.#{capitalize(action_name)}"

    # Build the path
    path =
      page_module_name
      |> Macro.underscore()
      |> String.replace(".", "/")

    file_path = "lib/#{path}.ex"

    # Build the content
    props_code =
      page.props
      |> Enum.map_join("\n", fn prop ->
        opts_str =
          case prop.opts do
            [] -> ""
            opts -> ", " <> inspect_opts(opts)
          end

        "  prop :#{prop.name}, #{prop.type}#{opts_str}"
      end)

    content = """
    defmodule #{page_module_name} do
      use NbInertia.Page

    #{props_code}

      def mount(_conn, _params) do
        # TODO: Move logic from the controller's action function here
        %{#{page.props |> Enum.map_join(", ", &"#{&1.name}: nil")}}
      end
    end
    """

    {file_path, content}
  end

  defp inspect_opts(opts) do
    opts
    |> Enum.map_join(", ", fn
      {k, v} when is_binary(v) -> "#{k}: #{inspect(v)}"
      {k, v} when is_atom(v) -> "#{k}: #{inspect(v)}"
      {k, v} -> "#{k}: #{inspect(v)}"
    end)
  end

  defp generate_router_changes(inertia_pages, web_module, resource_name) do
    page_resource = "#{resource_page_name(resource_name)}"
    actions = Enum.map(inertia_pages, &infer_action_name(&1.name, resource_name))

    # Check if this looks like a standard RESTful resource
    standard_actions = ~w(index show new create edit update delete)a
    action_atoms = Enum.map(actions, &String.to_atom/1)

    is_resource? =
      Enum.all?(action_atoms, &(&1 in standard_actions)) and length(action_atoms) >= 2

    route_lines =
      if is_resource? do
        only_opt =
          action_atoms
          |> Enum.filter(&(&1 in [:index, :show, :new, :edit]))
          |> Enum.map_join(", ", &inspect/1)

        """
        # Replace your existing routes for #{resource_name} with:
        scope "/", #{web_module} do
          pipe_through :browser

          inertia_resource "/#{String.downcase(resource_name)}", #{page_resource}, only: [#{only_opt}]
        end
        """
      else
        individual_routes =
          Enum.map_join(inertia_pages, "\n  ", fn page ->
            action = infer_action_name(page.name, resource_name)
            path = infer_path(page.name, resource_name)
            "inertia \"#{path}\", #{page_resource}.#{capitalize(action)}"
          end)

        """
        # Replace your existing routes for #{resource_name} with:
        scope "/", #{web_module} do
          pipe_through :browser

          #{individual_routes}
        end
        """
      end

    route_lines
  end

  # ── Naming helpers ─────────────────────────────────────────────────────────

  defp infer_web_module(controller_name) do
    controller_name
    |> String.split(".")
    |> Enum.take_while(&(!String.ends_with?(&1, "Controller")))
    |> Enum.join(".")
  end

  defp infer_resource_name(controller_name) do
    controller_name
    |> String.split(".")
    |> List.last()
    |> String.replace_suffix("Controller", "")
  end

  defp resource_page_name(resource_name) do
    "#{resource_name}Page"
  end

  defp infer_action_name(page_name, resource_name) do
    page_name
    |> Atom.to_string()
    |> String.replace_prefix("#{String.downcase(resource_name)}_", "")
    |> String.replace_prefix("#{Macro.underscore(resource_name)}_", "")
  end

  defp capitalize(str) do
    str
    |> String.split("_")
    |> Enum.map_join("", &String.capitalize/1)
  end

  defp infer_path(page_name, resource_name) do
    action = infer_action_name(page_name, resource_name)
    base = "/#{String.downcase(resource_name)}"

    case action do
      "index" -> "#{base}"
      "show" -> "#{base}/:id"
      "new" -> "#{base}/new"
      "edit" -> "#{base}/:id/edit"
      "create" -> "#{base}"
      "update" -> "#{base}/:id"
      "delete" -> "#{base}/:id"
      other -> "#{base}/#{other}"
    end
  end

  defp separator(title) do
    line = String.duplicate("─", max(60 - String.length(title) - 2, 4))
    "── #{title} #{line}"
  end
end
