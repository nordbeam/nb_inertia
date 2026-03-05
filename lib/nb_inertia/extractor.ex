defmodule NbInertia.Extractor do
  @moduledoc """
  Extracts colocated frontend components from Page modules to real `.tsx`/`.jsx` files.

  The extractor finds all Page modules with `render/0` containing `~TSX`/`~JSX` content,
  generates a TypeScript type preamble from prop declarations, and writes the complete
  file to the configured output directory (default: `.nb_inertia/pages/`).

  ## How It Works

  1. Discovers all loaded modules that define `__inertia_page__/0`
  2. Filters to those where `__inertia_has_render__/0` returns `true`
  3. For each module, calls `render/0` to get the component content
  4. Generates a type preamble from the module's prop declarations
  5. Combines the preamble with the render content
  6. Writes to the output directory using the component path

  ## Output

  Given `MyAppWeb.UsersPage.Index` with component `"Users/Index"`, the extractor
  writes to `.nb_inertia/pages/Users/Index.tsx`.

  ## Incremental Extraction

  The extractor is idempotent. When called with `incremental: true`, it compares
  a hash of the generated content with the existing file and only writes if changed.
  """

  alias NbInertia.Extractor.Preamble

  @default_output_dir ".nb_inertia/pages"

  @doc """
  Extracts all Page modules with `render/0` to the output directory.

  ## Options

    * `:output_dir` - Output directory (default: `".nb_inertia/pages"`)
    * `:incremental` - Only write files whose content has changed (default: `true`)
    * `:verbose` - Print extraction details (default: `false`)
    * `:clean` - Remove the output directory before extracting (default: `false`)
    * `:types_import_path` - Import path for generated types (default: `"@/types"`)
    * `:modules` - Explicit list of modules to extract (default: discover all)

  ## Returns

  A list of `{:ok, path}` or `{:error, module, reason}` tuples.
  """
  @spec extract_all(keyword()) ::
          list({:ok, String.t()} | {:skipped, String.t()} | {:error, module(), term()})
  def extract_all(opts \\ []) do
    output_dir = Keyword.get(opts, :output_dir, @default_output_dir)
    clean? = Keyword.get(opts, :clean, false)
    verbose? = Keyword.get(opts, :verbose, false)

    if clean? do
      File.rm_rf!(output_dir)
    end

    modules =
      case Keyword.get(opts, :modules) do
        nil -> discover_page_modules()
        mods -> mods
      end

    renderable =
      Enum.filter(modules, fn mod ->
        function_exported?(mod, :__inertia_has_render__, 0) &&
          mod.__inertia_has_render__()
      end)

    if verbose? do
      IO.puts("Found #{length(renderable)} page(s) with render/0")
    end

    results =
      Enum.map(renderable, fn mod ->
        result = extract_module(mod, opts)

        if verbose? do
          case result do
            {:ok, path} -> IO.puts("  Extracted: #{path}")
            {:skipped, path} -> IO.puts("  Unchanged: #{path}")
            {:error, _mod, reason} -> IO.puts("  Error: #{inspect(mod)} — #{reason}")
          end
        end

        result
      end)

    # Also generate companion channel config files for standalone pages (no render/0)
    standalone_with_channels =
      Enum.filter(modules, fn mod ->
        has_page? = function_exported?(mod, :__inertia_page__, 0)

        has_render? =
          function_exported?(mod, :__inertia_has_render__, 0) && mod.__inertia_has_render__()

        has_channel? =
          function_exported?(mod, :__inertia_channel__, 0) && mod.__inertia_channel__() != nil

        has_page? and not has_render? and has_channel?
      end)

    channel_results =
      Enum.map(standalone_with_channels, fn mod ->
        result = extract_channel_config(mod, opts)

        if verbose? do
          case result do
            {:ok, path} -> IO.puts("  Channel config: #{path}")
            {:skipped, path} -> IO.puts("  Channel unchanged: #{path}")
            {:error, _mod, reason} -> IO.puts("  Channel error: #{inspect(mod)} — #{reason}")
          end
        end

        result
      end)

    all_results = results ++ channel_results

    if verbose? do
      {ok, skipped, errors} = count_results(all_results)
      IO.puts("\nExtracted #{ok} file(s), #{skipped} unchanged, #{errors} error(s)")
    end

    all_results
  end

  @doc """
  Extracts a single Page module to the output directory.

  ## Options

  Same as `extract_all/1`.

  ## Returns

    * `{:ok, output_path}` - Successfully extracted
    * `{:skipped, output_path}` - File unchanged (incremental mode)
    * `{:error, module, reason}` - Extraction failed
  """
  @spec extract_module(module(), keyword()) ::
          {:ok, String.t()} | {:skipped, String.t()} | {:error, module(), term()}
  def extract_module(module, opts \\ []) do
    output_dir = Keyword.get(opts, :output_dir, @default_output_dir)
    incremental? = Keyword.get(opts, :incremental, true)
    types_import_path = Keyword.get(opts, :types_import_path, "@/types")

    try do
      # 1. Get component path
      component = module.__inertia_component__()

      # 2. Get render content
      content = module.render()

      # 3. Determine file extension from content analysis
      # We check if render/0 is defined — if it's TSX, we use .tsx, if JSX, .jsx
      # Since the sigil is a no-op, both return strings. We default to .tsx
      # unless the module has a __inertia_render_format__/0 function.
      ext = determine_extension(module)

      # 4. Get props for preamble
      props = module.__inertia_props__()

      # 4b. Get channel config if available
      channel_config = get_channel_config(module)

      # 4c. Check if camelize_props is enabled
      camelize? = get_camelize_props(module)

      # 5. Generate preamble (skip for JSX)
      preamble =
        if ext == ".tsx" and props != [] do
          source_path = derive_source_path(module)

          Preamble.generate(props,
            module: module,
            source_path: source_path,
            types_import_path: types_import_path,
            channel: channel_config,
            camelize_props: camelize?
          )
        else
          build_header_only(module, ext)
        end

      # 6. Combine preamble + render content
      full_content = combine_content(preamble, content)

      # 7. Determine output path
      output_path = Path.join(output_dir, "#{component}#{ext}")

      # 8. Write (with incremental check)
      write_file(output_path, full_content, incremental?)
    rescue
      e ->
        {:error, module, Exception.message(e)}
    end
  end

  @doc """
  Extracts a companion channel config file for a standalone Page module.

  This is used when a module declares a `channel` but has no `render/0`
  (standalone `.tsx` file pattern). The config is written to
  `.nb_inertia/channels/<Component>.config.ts`.

  ## Returns

    * `{:ok, output_path}` - Successfully extracted
    * `{:skipped, output_path}` - File unchanged (incremental mode)
    * `{:error, module, reason}` - Extraction failed
  """
  @spec extract_channel_config(module(), keyword()) ::
          {:ok, String.t()} | {:skipped, String.t()} | {:error, module(), term()}
  def extract_channel_config(module, opts \\ []) do
    output_dir = Keyword.get(opts, :output_dir, @default_output_dir)
    incremental? = Keyword.get(opts, :incremental, true)

    try do
      component = module.__inertia_component__()
      channel_config = module.__inertia_channel__()
      camelize? = get_camelize_props(module)

      # Generate channel config file
      content =
        Preamble.generate_channel_config(channel_config,
          module: module,
          camelize_props: camelize?
        )

      # Write to .nb_inertia/channels/<Component>.config.ts
      channels_dir = Path.join(Path.dirname(output_dir), "channels")
      output_path = Path.join(channels_dir, "#{component}.config.ts")

      write_file(output_path, content, incremental?)
    rescue
      e ->
        {:error, module, Exception.message(e)}
    end
  end

  @doc """
  Returns the default output directory for extracted pages.
  """
  @spec default_output_dir() :: String.t()
  def default_output_dir, do: @default_output_dir

  # ── Private Functions ──────────────────────────────────

  defp discover_page_modules do
    # Get all loaded modules and filter for Page modules
    :code.all_loaded()
    |> Enum.map(fn {mod, _path} -> mod end)
    |> Enum.filter(fn mod ->
      function_exported?(mod, :__inertia_page__, 0)
    end)
  end

  defp determine_extension(module) do
    if function_exported?(module, :__inertia_render_format__, 0) do
      case module.__inertia_render_format__() do
        :jsx -> ".jsx"
        :tsx -> ".tsx"
        _ -> ".tsx"
      end
    else
      ".tsx"
    end
  end

  defp derive_source_path(module) do
    # Try to derive source path from module name
    # MyAppWeb.UsersPage.Index → lib/my_app_web/inertia/users_page/index.ex
    segments =
      module
      |> Module.split()
      |> Enum.map(&Macro.underscore/1)

    "lib/" <> Enum.join(segments, "/") <> ".ex"
  end

  defp build_header_only(module, ".jsx") do
    "// AUTO-GENERATED from #{inspect(module)} — do not edit directly\n// Source: #{derive_source_path(module)}\n"
  end

  defp build_header_only(module, _ext) do
    source_path = derive_source_path(module)

    Preamble.generate([],
      module: module,
      source_path: source_path
    )
  end

  defp combine_content(preamble, render_content) do
    preamble = String.trim_trailing(preamble)
    render_content = String.trim(render_content)

    "#{preamble}\n\n#{render_content}\n"
  end

  defp write_file(output_path, content, incremental?) do
    # Ensure directory exists
    output_path |> Path.dirname() |> File.mkdir_p!()

    if incremental? and file_unchanged?(output_path, content) do
      {:skipped, output_path}
    else
      File.write!(output_path, content)
      {:ok, output_path}
    end
  end

  defp file_unchanged?(path, new_content) do
    case File.read(path) do
      {:ok, existing} ->
        :crypto.hash(:md5, existing) == :crypto.hash(:md5, new_content)

      {:error, _} ->
        false
    end
  end

  defp get_channel_config(module) do
    if function_exported?(module, :__inertia_channel__, 0) do
      module.__inertia_channel__()
    else
      nil
    end
  end

  defp get_camelize_props(module) do
    if function_exported?(module, :__inertia_options__, 0) do
      module.__inertia_options__() |> Map.get(:camelize_props, false) |> Kernel.==(true)
    else
      false
    end
  end

  defp count_results(results) do
    Enum.reduce(results, {0, 0, 0}, fn
      {:ok, _}, {ok, skip, err} -> {ok + 1, skip, err}
      {:skipped, _}, {ok, skip, err} -> {ok, skip + 1, err}
      {:error, _, _}, {ok, skip, err} -> {ok, skip, err + 1}
    end)
  end
end
