defmodule Mix.Tasks.NbInertia.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs and configures NbInertia with Inertia.js in a Phoenix application."
  end

  def example do
    "mix nb_inertia.install --client-framework react --typescript"
  end

  def long_doc do
    """
    Installs and configures NbInertia with Inertia.js in a Phoenix application.

    This installer wraps and enhances the base Inertia.js library with additional
    features like declarative page DSL, type-safe props, and shared props.

    ## Installation Steps

    1. Adds `{:nb_inertia, "~> 0.1"}` to mix.exs dependencies
    2. Adds `{:inertia, "~> 2.5"}` to mix.exs dependencies
    3. Adds `{:nb_ts, "~> 0.1"}` when --typescript is used
    4. Sets up controller helpers (use NbInertia.Controller)
    5. Sets up HTML helpers (import Inertia.HTML)
    6. Adds `plug Inertia.Plug` to the browser pipeline
    7. Adds configuration to config/config.exs under :nb_inertia namespace
    8. Updates root layout template (with nb_vite support if detected)
    9. Configures asset bundler (esbuild by default, or skips if nb_vite is present)
    10. Detects and uses appropriate package manager (npm, yarn, pnpm, or bun)
    11. Installs npm packages including @nordbeam/nb-inertia for enhanced components
    12. Creates assets/js/lib/inertia.ts with enhanced router, Link, and useForm
    13. Sets up TypeScript type generation (when --typescript is used)
    14. Creates sample Inertia page component
    15. Prints helpful next steps

    ## Usage

    ```bash
    mix nb_inertia.install
    ```

    ## Options

        --client-framework FRAMEWORK  Framework to use for the client-side integration
                                      (react, vue, or svelte). Default is react.
        --camelize-props              Enable camelCase for props (stored in :nb_inertia config)
        --history-encrypt             Enable history encryption (stored in :nb_inertia config)
        --typescript                  Enable TypeScript
        --ssr                         Enable Server-Side Rendering (SSR) support
        --with-flop                   Install nb_flop for pagination, sorting, and filtering
        --table                       Generate sample Table DSL module (requires --with-flop)
        --yes                         Don't prompt for confirmations

    ## Examples

    ```bash
    # Install with React and TypeScript
    mix nb_inertia.install --client-framework react --typescript

    # Install with Vue and camelized props
    mix nb_inertia.install --client-framework vue --camelize-props

    # Install with React, TypeScript, and history encryption
    mix nb_inertia.install --client-framework react --typescript --history-encrypt --camelize-props

    # Install with React, TypeScript, and SSR support
    mix nb_inertia.install --client-framework react --typescript --ssr

    # Install with React, TypeScript, and Flop integration
    mix nb_inertia.install --client-framework react --typescript --with-flop

    # Install with Flop and sample Table DSL
    mix nb_inertia.install --client-framework react --typescript --with-flop --table
    ```

    ## Using with nb_vite

    If you have `nb_vite` in your dependencies, the installer will automatically:
    - Skip esbuild configuration (Vite handles bundling)
    - Generate a root layout that uses NbVite helper functions
    - Detect if Bun is configured via nb_vite and use it for package installation
    - Use the appropriate package manager (bun, pnpm, yarn, or npm)

    To use nb_inertia with nb_vite and Bun:

    ```bash
    # First install nb_vite with Bun support
    mix nb_vite.install --bun --typescript

    # Then install nb_inertia
    mix nb_inertia.install --client-framework react --typescript
    ```

    The installer will detect the nb_vite setup and configure accordingly.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NbInertia.Install do
    @shortdoc __MODULE__.Docs.short_doc()

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task
    require Igniter.Code.Common

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :nb,
        schema: [
          client_framework: :string,
          camelize_props: :boolean,
          history_encrypt: :boolean,
          typescript: :boolean,
          ssr: :boolean,
          with_flop: :boolean,
          table: :boolean,
          yes: :boolean
        ],
        example: __MODULE__.Docs.example(),
        defaults: [client_framework: "react", with_flop: false, table: false],
        positional: [],
        composes: ["deps.get"]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Igniter.Project.Formatter.import_dep(:nb_inertia)
      |> add_dependencies()
      |> setup_controller_helpers()
      |> setup_html_helpers()
      |> setup_router()
      |> add_inertia_config()
      |> create_modal_config()
      |> update_root_layout()
      |> maybe_update_asset_bundler_config()
      |> setup_client()
      |> maybe_setup_ssr()
      |> maybe_setup_nb_ts()
      |> maybe_setup_nb_flop()
      |> create_sample_page()
      |> update_page_controller()
      |> create_lib_inertia()
      |> copy_modal_components()
      |> print_next_steps()
    end

    @doc false
    def using_nb_vite?(igniter) do
      # Check if nb_vite is in the dependencies
      case Igniter.Project.Deps.get_dep(igniter, :nb_vite) do
        {:ok, _} -> true
        _ -> false
      end
    end

    @doc false
    def maybe_update_asset_bundler_config(igniter) do
      if using_nb_vite?(igniter) do
        # If using nb_vite, skip esbuild configuration
        igniter
      else
        # If not using nb_vite, configure esbuild
        update_esbuild_config(igniter)
      end
    end

    @doc false
    def add_dependencies(igniter) do
      ssr_enabled = igniter.args.options[:ssr] || false
      typescript_enabled = igniter.args.options[:typescript] || false

      # Add inertia dependency (nb_inertia is already added by igniter.install)
      igniter = Igniter.Project.Deps.add_dep(igniter, {:inertia, "~> 2.5"})

      # Add nb_ts if TypeScript is enabled and not already present
      igniter =
        if typescript_enabled do
          # Only add if not already present (nb_stack might have added it already)
          case Igniter.Project.Deps.get_dep(igniter, :nb_ts) do
            {:ok, _} ->
              igniter

            {:error, _} ->
              Igniter.Project.Deps.add_dep(igniter, {:nb_ts, github: "nordbeam/nb_ts"})
          end
        else
          igniter
        end

      # Only add deno_rider if SSR is enabled AND nb_vite is present
      if ssr_enabled && using_nb_vite?(igniter) do
        Igniter.Project.Deps.add_dep(igniter, {:deno_rider, "~> 0.2"})
      else
        igniter
      end
    end

    @doc false
    def setup_controller_helpers(igniter) do
      update_web_ex_helper(igniter, :controller, fn zipper ->
        use_code = "use NbInertia.Controller"

        with {:ok, zipper} <- move_to_last_import_or_alias(zipper) do
          {:ok, Igniter.Code.Common.add_code(zipper, use_code)}
        end
      end)
    end

    @doc false
    def setup_html_helpers(igniter) do
      update_web_ex_helper(igniter, :html, fn zipper ->
        import_code = """
            import Inertia.HTML
        """

        with {:ok, zipper} <- move_to_last_import_or_alias(zipper) do
          {:ok, Igniter.Code.Common.add_code(zipper, import_code)}
        end
      end)
    end

    # Run an update function within the quote do ... end block inside a *web.ex helper function
    defp update_web_ex_helper(igniter, helper_name, update_fun) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)

      case Igniter.Project.Module.find_module(igniter, web_module) do
        {:ok, {igniter, _source, _zipper}} ->
          Igniter.Project.Module.find_and_update_module!(igniter, web_module, fn zipper ->
            with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, helper_name, 0),
                 {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
              Igniter.Code.Common.within(zipper, update_fun)
            else
              :error ->
                {:warning, "Could not find #{helper_name}/0 function in #{inspect(web_module)}"}
            end
          end)

        {:error, igniter} ->
          Igniter.add_warning(
            igniter,
            "Could not find web module #{inspect(web_module)}. You may need to manually add NbInertia helpers."
          )
      end
    end

    defp move_to_last_import_or_alias(zipper) do
      # Try to find the last import first
      case Igniter.Code.Common.move_to_last(
             zipper,
             &Igniter.Code.Function.function_call?(&1, :import)
           ) do
        {:ok, zipper} ->
          {:ok, zipper}

        _ ->
          # If no imports, try to find the last alias
          Igniter.Code.Common.move_to_last(
            zipper,
            &Igniter.Code.Function.function_call?(&1, :alias)
          )
      end
    end

    @doc false
    def setup_router(igniter) do
      igniter
      |> Igniter.Libs.Phoenix.append_to_pipeline(:browser, "plug Inertia.Plug")
      |> Igniter.Libs.Phoenix.append_to_pipeline(:browser, "plug NbInertia.Plugs.ModalHeaders")
    end

    @doc false
    def add_inertia_config(igniter) do
      # Get endpoint module name based on app name
      {igniter, endpoint_module} = Igniter.Libs.Phoenix.select_endpoint(igniter)

      # Determine configuration based on options
      camelize_props = igniter.args.options[:camelize_props] || false
      history_encryption = igniter.args.options[:history_encrypt] || false

      config_options = [
        endpoint: endpoint_module
      ]

      # Add camelize_props config if specified
      config_options =
        if camelize_props do
          Keyword.put(config_options, :camelize_props, true)
        else
          config_options
        end

      # Add history encryption config if specified
      config_options =
        if history_encryption do
          Keyword.put(config_options, :history, encrypt: true)
        else
          config_options
        end

      # Add the configuration to config.exs under :nb_inertia namespace
      Enum.reduce(config_options, igniter, fn {key, value}, igniter ->
        Igniter.Project.Config.configure(
          igniter,
          "config.exs",
          :nb_inertia,
          [key],
          value
        )
      end)
    end

    @doc false
    def create_modal_config(igniter) do
      # Path to the template file
      template_path =
        Path.join([:code.priv_dir(:nb_inertia), "templates", "nb_inertia_modal.exs"])

      # Destination path
      dest_path = "config/nb_inertia_modal.exs"

      # Only create if template exists and file doesn't exist
      if File.exists?(template_path) do
        if Igniter.exists?(igniter, dest_path) do
          # File already exists, don't overwrite
          igniter
        else
          # File doesn't exist, copy template
          content = File.read!(template_path)

          # Just create the file, user can manually import it
          Igniter.create_new_file(igniter, dest_path, content)
        end
      else
        igniter
      end
    end

    @doc false
    def update_root_layout(igniter) do
      file_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "components",
          "layouts",
          "root.html.heex"
        ])

      if using_nb_vite?(igniter) do
        # When using nb_vite, append Inertia-specific lines to existing root.html.heex
        append_inertia_to_vite_layout(igniter, file_path)
      else
        # When not using nb_vite, create complete root.html.heex with esbuild config
        content = inertia_root_html_esbuild()
        Igniter.create_new_file(igniter, file_path, content, on_exists: :overwrite)
      end
    end

    defp append_inertia_to_vite_layout(igniter, file_path) do
      client_framework = igniter.args.options[:client_framework]
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"

      # Build the lines to append (Inertia components + app.tsx entry)
      lines_to_add = build_inertia_vite_lines(client_framework, extension)

      # Update the file by finding the </head> tag and inserting before it
      igniter
      |> Igniter.include_existing_file(file_path)
      |> Igniter.update_file(file_path, fn source ->
        Rewrite.Source.update(source, :content, fn
          content when is_binary(content) ->
            # Check if inertia components are already present
            if String.contains?(content, "<.inertia_title>") do
              # Inertia already configured, skip
              content
            else
              # Check if app.tsx/jsx already exists to avoid duplicates
              already_has_inertia_entry = String.contains?(content, "js/app.#{extension}")

              # Build the lines - only include app.tsx if not already present
              final_lines =
                if already_has_inertia_entry do
                  build_inertia_components_only(client_framework)
                else
                  lines_to_add
                end

              # Add the inertia lines before </head>
              if String.contains?(content, "</head>") do
                String.replace(content, "</head>", "#{final_lines}  </head>", global: false)
              else
                # If no </head> tag found, return content unchanged
                content
              end
            end

          content ->
            content
        end)
      end)
    end

    defp build_inertia_vite_lines(client_framework, extension) do
      react_refresh_line =
        if client_framework == "react" do
          "    <%= NbVite.react_refresh() %>\n"
        else
          ""
        end

      """
          <.inertia_title><%= assigns[:page_title] %></.inertia_title>
          <.inertia_head content={@inertia_head} />
      #{react_refresh_line}    <%= NbVite.vite_assets("js/app.#{extension}") %>
      """
    end

    # Build only the Inertia component lines (without vite_assets)
    # Used when app.tsx already exists in the layout to avoid duplicates
    defp build_inertia_components_only(client_framework) do
      react_refresh_line =
        if client_framework == "react" do
          "    <%= NbVite.react_refresh() %>\n"
        else
          ""
        end

      "    <.inertia_title><%= assigns[:page_title] %></.inertia_title>\n    <.inertia_head content={@inertia_head} />\n#{react_refresh_line}"
    end

    defp web_dir(igniter) do
      igniter
      |> Igniter.Libs.Phoenix.web_module()
      |> inspect()
      |> Macro.underscore()
    end

    defp inertia_root_html_esbuild() do
      """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="csrf-token" content={get_csrf_token()} />
          <.inertia_title><%= assigns[:page_title] %></.inertia_title>
          <.inertia_head content={@inertia_head} />
          <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
          <script type="module" defer phx-track-static src={~p"/assets/app.js"} />
        </head>
        <body>
          {@inner_content}
        </body>
      </html>
      """
    end

    @doc false
    def update_esbuild_config(igniter) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :esbuild,
        [:version],
        "0.21.5"
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :esbuild,
        [Igniter.Project.Application.app_name(igniter)],
        {:code,
         Sourceror.parse_string!("""
         [
          args:
            ~w(js/app.jsx --bundle --chunk-names=chunks/[name]-[hash] --splitting --format=esm  --target=es2020 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
          cd: Path.expand("../assets", __DIR__),
          env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
         ]
         """)}
      )
      |> Igniter.add_task("esbuild.install")
    end

    @doc false
    def setup_client(igniter) do
      case igniter.args.options[:client_framework] do
        "react" ->
          typescript = igniter.args.options[:typescript] || false
          extension = if typescript, do: "tsx", else: "jsx"

          igniter
          |> install_client_package()
          |> maybe_create_typescript_config()
          |> maybe_update_vite_config_for_react()
          |> Igniter.create_new_file("assets/js/app.#{extension}", inertia_app_jsx(igniter),
            on_exists: :overwrite
          )

        framework when framework in ["vue", "svelte"] ->
          igniter
          |> install_client_package()
          |> maybe_create_typescript_config()

        _ ->
          igniter
      end
    end

    @doc false
    def maybe_update_vite_config_for_react(igniter) do
      if using_nb_vite?(igniter) do
        update_vite_config_for_react(igniter)
      else
        igniter
      end
    end

    defp update_vite_config_for_react(igniter) do
      vite_config_path = "assets/vite.config.js"
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"

      if Igniter.exists?(igniter, vite_config_path) do
        igniter
        |> Igniter.include_existing_file(vite_config_path)
        |> Igniter.update_file(vite_config_path, fn source ->
          Rewrite.Source.update(source, :content, fn
            content when is_binary(content) ->
              # Check if React plugin is already configured
              if String.contains?(content, "@vitejs/plugin-react") do
                # Already configured, but still need to add app.tsx to input if not present
                if String.contains?(content, "js/app.#{extension}") do
                  content
                else
                  add_app_to_vite_input(content, extension)
                end
              else
                # Add React plugin import, configuration, and app.tsx to input
                content
                |> add_react_import_to_vite_config()
                |> add_react_plugin_to_vite_config()
                |> add_app_to_vite_input(extension)
              end

            content ->
              content
          end)
        end)
      else
        igniter
      end
    end

    defp add_react_import_to_vite_config(content) do
      # Add the import after other imports, before the export
      if String.contains?(content, "import") do
        # Find the last import and add react import after it
        lines = String.split(content, "\n")

        {imports, rest} =
          Enum.split_while(lines, fn line ->
            String.starts_with?(String.trim(line), "import") or String.trim(line) == ""
          end)

        # Add react import at the end of imports
        react_import = "import react from '@vitejs/plugin-react'"

        # Rebuild content
        Enum.join(imports ++ [react_import, ""] ++ rest, "\n")
      else
        # No imports found, add at the beginning
        "import react from '@vitejs/plugin-react'\n\n" <> content
      end
    end

    defp add_react_plugin_to_vite_config(content) do
      # Add react() with babel configuration to the plugins array
      # Look for "plugins: [" and add react() with babel plugin as first plugin
      react_plugin =
        "    react({\n      babel: {\n        plugins: ['babel-plugin-react-compiler'],\n      },\n    }),\n"

      content
      |> String.replace(
        ~r/(plugins:\s*\[\s*\n)/,
        "\\1#{react_plugin}",
        global: false
      )
    end

    defp add_app_to_vite_input(content, extension) do
      # ADD js/app.{tsx|jsx} to the input array (keeping the existing app.ts/app.js)
      # This allows both regular Phoenix pages (app.ts) and Inertia pages (app.tsx) to work
      # Match: input: ['js/app.ts', ...] or input: ['js/app.js', ...]
      # Result: input: ['js/app.ts', 'js/app.tsx', ...] (adds the new entry)

      # First check if app.tsx/jsx already exists in the input
      if String.contains?(content, "js/app.#{extension}") do
        content
      else
        # Add the new entry after the existing app.ts/app.js entry
        content
        |> String.replace(
          ~r/(input:\s*\[['"]js\/app\.(ts|js)['"])/,
          "\\1, 'js/app.#{extension}'",
          global: false
        )
      end
    end

    @doc false
    def using_bun?(_igniter) do
      # Check if bun lockfile exists or bun is available
      File.exists?("assets/bun.lockb") || System.find_executable("bun") != nil
    end

    @doc false
    def get_package_manager_command(igniter) do
      # First check if using Bun via nb_vite configuration
      if using_bun?(igniter) do
        "bun"
      else
        # Detect package manager from lockfiles in assets directory
        detect_package_manager_from_lockfile()
      end
    end

    defp detect_package_manager_from_lockfile do
      cond do
        File.exists?("assets/bun.lockb") ->
          "bun"

        File.exists?("assets/pnpm-lock.yaml") ->
          "pnpm"

        File.exists?("assets/yarn.lock") ->
          "yarn"

        File.exists?("assets/package-lock.json") ->
          "npm"

        # Fallback to system detection if no lockfile exists
        System.find_executable("bun") ->
          "bun"

        System.find_executable("pnpm") ->
          "pnpm"

        System.find_executable("yarn") ->
          "yarn"

        true ->
          "npm"
      end
    end

    defp maybe_create_typescript_config(igniter) do
      if igniter.args.options[:typescript] do
        Igniter.create_new_file(igniter, "assets/tsconfig.json", react_tsconfig_json(),
          on_exists: :overwrite
        )
      else
        igniter
      end
    end

    defp install_client_package(igniter) do
      typescript = igniter.args.options[:typescript] || false
      client_framework = igniter.args.options[:client_framework]

      igniter
      |> install_client_main_packages(client_framework)
      |> maybe_install_react_dev_deps(client_framework)
      |> maybe_install_typescript_deps(client_framework, typescript)
    end

    defp install_client_main_packages(igniter, "react") do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      # Add @vitejs/plugin-react if using nb_vite
      react_plugin = if using_nb_vite?(igniter), do: " @vitejs/plugin-react", else: ""

      # Core packages + @radix-ui/react-visually-hidden for modal accessibility
      base_packages =
        "@inertiajs/react @nordbeam/nb-inertia react react-dom axios @radix-ui/react-visually-hidden"

      install_cmd =
        case pkg_manager do
          "bun" ->
            "bun add --cwd #{assets_dir} #{base_packages}#{react_plugin}"

          "pnpm" ->
            "pnpm add --dir #{assets_dir} #{base_packages}#{react_plugin}"

          "yarn" ->
            "yarn --cwd #{assets_dir} add #{base_packages}#{react_plugin}"

          _ ->
            "npm install --prefix #{assets_dir} #{base_packages}#{react_plugin}"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp install_client_main_packages(igniter, "vue") do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" -> "bun add --cwd #{assets_dir} @inertiajs/vue3 vue vue-loader axios"
          "pnpm" -> "pnpm add --dir #{assets_dir} @inertiajs/vue3 vue vue-loader axios"
          "yarn" -> "yarn --cwd #{assets_dir} add @inertiajs/vue3 vue vue-loader axios"
          _ -> "npm install --prefix #{assets_dir} @inertiajs/vue3 vue vue-loader axios"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp install_client_main_packages(igniter, "svelte") do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" -> "bun add --cwd #{assets_dir} @inertiajs/svelte svelte axios"
          "pnpm" -> "pnpm add --dir #{assets_dir} @inertiajs/svelte svelte axios"
          "yarn" -> "yarn --cwd #{assets_dir} add @inertiajs/svelte svelte axios"
          _ -> "npm install --prefix #{assets_dir} @inertiajs/svelte svelte axios"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_react_dev_deps(igniter, "react") do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" ->
            "bun add --cwd #{assets_dir} -D babel-plugin-react-compiler@latest"

          "pnpm" ->
            "pnpm add --dir #{assets_dir} -D babel-plugin-react-compiler@latest"

          "yarn" ->
            "yarn --cwd #{assets_dir} add -D babel-plugin-react-compiler@latest"

          _ ->
            "npm install --prefix #{assets_dir} -D babel-plugin-react-compiler@latest"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_react_dev_deps(igniter, _), do: igniter

    defp maybe_install_typescript_deps(igniter, _, false), do: igniter

    defp maybe_install_typescript_deps(igniter, "react", true) do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" ->
            "bun add --cwd #{assets_dir} --dev @types/react @types/react-dom typescript"

          "pnpm" ->
            "pnpm add --dir #{assets_dir} --save-dev @types/react @types/react-dom typescript"

          "yarn" ->
            "yarn --cwd #{assets_dir} add --dev @types/react @types/react-dom typescript"

          _ ->
            "npm install --prefix #{assets_dir} --save-dev @types/react @types/react-dom typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_typescript_deps(igniter, "vue", true) do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" ->
            "bun add --cwd #{assets_dir} --dev @vue/compiler-sfc vue-tsc typescript"

          "pnpm" ->
            "pnpm add --dir #{assets_dir} --save-dev @vue/compiler-sfc vue-tsc typescript"

          "yarn" ->
            "yarn --cwd #{assets_dir} add --dev @vue/compiler-sfc vue-tsc typescript"

          _ ->
            "npm install --prefix #{assets_dir} --save-dev @vue/compiler-sfc vue-tsc typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_typescript_deps(igniter, "svelte", true) do
      pkg_manager = get_package_manager_command(igniter)
      assets_dir = "assets"

      install_cmd =
        case pkg_manager do
          "bun" ->
            "bun add --cwd #{assets_dir} --dev svelte-loader svelte-preprocess typescript"

          "pnpm" ->
            "pnpm add --dir #{assets_dir} --save-dev svelte-loader svelte-preprocess typescript"

          "yarn" ->
            "yarn --cwd #{assets_dir} add --dev svelte-loader svelte-preprocess typescript"

          _ ->
            "npm install --prefix #{assets_dir} --save-dev svelte-loader svelte-preprocess typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp react_tsconfig_json() do
      ~S"""
      {
        "compilerOptions": {
          "target": "ES2020",
          "useDefineForClassFields": true,
          "lib": ["ES2020", "DOM", "DOM.Iterable"],
          "module": "ESNext",
          "skipLibCheck": true,
          "moduleResolution": "bundler",
          "allowImportingTsExtensions": true,
          "resolveJsonModule": true,
          "isolatedModules": true,
          "noEmit": true,
          "jsx": "react-jsx",
          "strict": true,
          "noUnusedLocals": true,
          "noUnusedParameters": true,
          "noFallthroughCasesInSwitch": true,
          "allowJs": true,
          "forceConsistentCasingInFileNames": true,
          "esModuleInterop": true,
          "baseUrl": ".",
          "paths": {
            "@/*": ["./js/*"]
          }
        },
        "include": ["js/**/*.ts", "js/**/*.tsx", "js/**/*.js", "js/**/*.jsx"],
        "exclude": ["node_modules"]
      }
      """
    end

    defp inertia_app_jsx(igniter) do
      # The app.jsx/tsx file is the same for both esbuild and Vite
      # Vite natively handles JSX/TSX, esbuild is configured to handle it too
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"

      """
      import React from "react";
      import axios from "axios";

      import { createInertiaApp } from "@inertiajs/react";
      import { createRoot } from "react-dom/client";

      axios.defaults.xsrfHeaderName = "x-csrf-token";

      const pages = import.meta.glob("./pages/**/*.#{extension}");

      createInertiaApp({
        resolve: async (name) => {
          const path = `./pages/${name}.#{extension}`;
          const resolver = pages[path];
          if (!resolver) {
            throw new Error(`Page not found: ${name}`);
          }
          return resolver();
        },
        setup({ App, el, props }) {
          createRoot(el).render(<App {...props} />);
        },
      });
      """
    end

    @doc false
    def maybe_setup_ssr(igniter) do
      ssr_enabled = igniter.args.options[:ssr] || false

      if ssr_enabled && using_nb_vite?(igniter) do
        igniter
        |> create_ssr_entry_files()
        |> create_vite_plugins()
        # Skip automatic vite.config transformation - too complex for regex
        # Users will update vite.config.js manually following the instructions
        # |> update_vite_config_for_ssr()
        |> add_ssr_config()
        |> add_ssr_to_supervision_tree()
      else
        if ssr_enabled do
          Igniter.add_warning(
            igniter,
            """
            SSR support requires nb_vite but it was not found in your dependencies.

            To enable SSR:
            1. First install nb_vite: mix nb_vite.install --typescript
            2. Then run: mix nb_inertia.install --client-framework react --typescript --ssr

            SSR setup has been skipped for now.
            """
          )
        else
          igniter
        end
      end
    end

    defp create_ssr_entry_files(igniter) do
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"

      igniter
      # Create unified ssr.tsx - uses the same code as ssr_dev for Vite Module Runner API
      |> Igniter.create_new_file("assets/js/ssr.#{extension}", ssr_dev_template(),
        on_exists: :skip
      )
      # Also create ssr_prod for production builds with DenoRider (eager loading)
      |> Igniter.create_new_file("assets/js/ssr_prod.#{extension}", ssr_prod_template(),
        on_exists: :skip
      )
    end

    defp create_vite_plugins(igniter) do
      Igniter.create_new_file(
        igniter,
        "assets/vite-plugins/node-prefix-plugin.js",
        node_prefix_plugin(),
        on_exists: :skip
      )
    end

    defp add_ssr_config(igniter) do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :nb_inertia,
        [:ssr],
        true
      )
    end

    defp add_ssr_to_supervision_tree(igniter) do
      Igniter.Project.Application.add_new_child(igniter, NbInertia.SSR)
    end

    defp ssr_dev_template() do
      ~S"""
      import React from "react";
      import ReactDOMServer from "react-dom/server";
      import { createInertiaApp } from "@inertiajs/react";

      /**
       * Development SSR entry point with on-demand page loading
       *
       * Creates the page map once at module level, then only loads
       * the specific requested page on each render.
       */
      // Lazy loading - create import functions once at module level
      const pages = import.meta.glob("./pages/**/*.tsx");

      export async function render(page) {
        return await createInertiaApp({
          page,
          render: ReactDOMServer.renderToString,
          resolve: async (name) => {
            const pagePath = `./pages/${name}.tsx`;

            if (!pages[pagePath]) {
              // List available pages for debugging
              const availablePages = Object.keys(pages)
                .map(p => p.replace('./pages/', '').replace('.tsx', ''))
                .sort();

              throw new Error(
                `❌ SSR Page Not Found\n\n` +
                `Component: ${name}\n` +
                `Expected file: assets/js/pages/${name}.tsx\n\n` +
                `This page file doesn't exist or wasn't found by Vite's glob.\n\n` +
                `Common causes:\n` +
                `• The file hasn't been created yet\n` +
                `• The file name doesn't match the component name\n` +
                `• The file has the wrong extension (e.g., .tsxx instead of .tsx)\n` +
                `• The component name in your controller doesn't match the file path\n\n` +
                `Available pages (${availablePages.length}):\n` +
                availablePages.map(p => `  - ${p}`).join('\n')
              );
            }

            // Dynamically import only the requested page
            return await pages[pagePath]();
          },
          setup: ({ App, props }) => <App {...props} />,
        });
      }
      """
    end

    defp ssr_prod_template() do
      ~S"""
      import React from "react";
      import ReactDOMServer from "react-dom/server";
      import { createInertiaApp } from "@inertiajs/react";

      /**
       * Production SSR entry point with eager page loading
       *
       * Uses eager import.meta.glob() to bundle all pages into the SSR bundle.
       * This is required for Deno/DenoRider which doesn't support dynamic imports
       * in the same way as Node.js.
       */
      export async function render(page) {
        return await createInertiaApp({
          page,
          render: ReactDOMServer.renderToString,
          resolve: async (name) => {
            // Eager loading - all pages are bundled
            const pages = import.meta.glob("./pages/**/*.tsx", { eager: true });
            const pagePath = `./pages/${name}.tsx`;

            if (!pages[pagePath]) {
              // List available pages for debugging
              const availablePages = Object.keys(pages)
                .map(p => p.replace('./pages/', '').replace('.tsx', ''))
                .sort();

              throw new Error(
                `❌ SSR Page Not Found\n\n` +
                `Component: ${name}\n` +
                `Expected file: assets/js/pages/${name}.tsx\n\n` +
                `This page file doesn't exist or wasn't bundled in the SSR build.\n\n` +
                `Common causes:\n` +
                `• The file hasn't been created yet\n` +
                `• The file name doesn't match the component name\n` +
                `• The file has the wrong extension (e.g., .tsxx instead of .tsx)\n` +
                `• The component name in your controller doesn't match the file path\n` +
                `• The SSR bundle needs to be rebuilt (run: bun build:ssr)\n\n` +
                `Available pages (${availablePages.length}):\n` +
                availablePages.map(p => `  - ${p}`).join('\n')
              );
            }

            return pages[pagePath];
          },
          setup: ({ App, props }) => <App {...props} />,
        });
      }
      """
    end

    defp node_prefix_plugin() do
      """
      /**
       * Vite plugin to add 'node:' prefix to Node.js built-in modules
       *
       * This is required for Deno compatibility in SSR builds.
       * Deno requires the 'node:' prefix for Node.js built-ins (e.g., 'node:path'),
       * while Vite and most Node.js code uses bare imports (e.g., 'path').
       *
       * This plugin transforms the imports during the SSR build to make the
       * bundle compatible with Deno.
       */

      const nodeBuiltins = new Set([
        'assert', 'async_hooks', 'buffer', 'child_process', 'cluster', 'console',
        'constants', 'crypto', 'dgram', 'diagnostics_channel', 'dns', 'domain',
        'events', 'fs', 'http', 'http2', 'https', 'inspector', 'module', 'net',
        'os', 'path', 'perf_hooks', 'process', 'punycode', 'querystring',
        'readline', 'repl', 'stream', 'string_decoder', 'sys', 'timers',
        'tls', 'trace_events', 'tty', 'url', 'util', 'v8', 'vm', 'wasi',
        'worker_threads', 'zlib'
      ]);

      export default function nodePrefixPlugin() {
        return {
          name: 'node-prefix',
          enforce: 'pre',

          // Transform imports to add 'node:' prefix to Node.js built-ins
          resolveId(source, importer, options) {
            // Only apply during SSR build
            if (!options.ssr) return null;

            // Check if this is a Node.js built-in module
            if (nodeBuiltins.has(source)) {
              return `node:${source}`;
            }

            // Check for path-based node built-ins (e.g., 'path/posix')
            const baseModule = source.split('/')[0];
            if (nodeBuiltins.has(baseModule)) {
              return source.replace(baseModule, `node:${baseModule}`);
            }

            return null;
          }
        };
      }
      """
    end

    @doc false
    def maybe_setup_nb_ts(igniter) do
      typescript_enabled = igniter.args.options[:typescript] || false

      if typescript_enabled do
        # Compose the nb_ts installer instead of duplicating setup logic
        Igniter.compose_task(igniter, "nb_ts.install", ["--output-dir", "assets/js/types"])
      else
        igniter
      end
    end

    @doc false
    def maybe_setup_nb_flop(igniter) do
      with_flop = igniter.args.options[:with_flop] || false
      with_table = igniter.args.options[:table] || false

      if with_flop do
        # Only add nb_flop dependency if not already present
        igniter =
          case Igniter.Project.Deps.get_dep(igniter, :nb_flop) do
            {:ok, _} ->
              igniter

            {:error, _} ->
              Igniter.Project.Deps.add_dep(igniter, {:nb_flop, github: "nordbeam/nb_flop"})
          end

        # Build args for nb_flop.install
        args = if with_table, do: ["--table"], else: []

        # Compose the nb_flop installer
        Igniter.compose_task(igniter, "nb_flop.install", args)
      else
        igniter
      end
    end

    @doc false
    def create_sample_page(igniter) do
      client_framework = igniter.args.options[:client_framework]
      typescript = igniter.args.options[:typescript] || false

      case client_framework do
        "react" ->
          extension = if typescript, do: "tsx", else: "jsx"
          sample_page = sample_react_page()

          Igniter.create_new_file(igniter, "assets/js/pages/Home.#{extension}", sample_page,
            on_exists: :skip
          )

        _ ->
          igniter
      end
    end

    defp sample_react_page() do
      """
      import React from "react";

      export default function Home({ greeting }) {
        return (
          <div style={{ padding: "2rem", fontFamily: "sans-serif" }}>
            <h1>{greeting || "Welcome to NbInertia!"}</h1>
            <p>
              This is a sample Inertia.js page component created by the nb_inertia installer.
            </p>
            <p>
              Edit this file at <code>assets/js/pages/Home.jsx</code> to get started.
            </p>

            <div style={{ marginTop: "2rem" }}>
              <h2>Next Steps</h2>
              <ul>
                <li>Create more page components in assets/js/pages/</li>
                <li>Use <code>inertia_page</code> macro to declare pages in your controllers</li>
                <li>Render pages with <code>render_inertia(conn, :page_name, props)</code></li>
              </ul>
            </div>

            <div style={{ marginTop: "2rem", padding: "1rem", background: "#f0f0f0", borderRadius: "0.5rem" }}>
              <h3>Example Controller</h3>
              <pre style={{ background: "white", padding: "1rem", borderRadius: "0.25rem", overflow: "auto" }}>
                {`defmodule MyAppWeb.PageController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :home do
          prop :greeting, :string
        end

        def home(conn, _params) do
          render_inertia(conn, :home,
            greeting: "Hello from NbInertia!"
          )
        end
      end`}
              </pre>
            </div>
          </div>
        );
      }
      """
    end

    @doc false
    def update_page_controller(igniter) do
      # Update the PageController to use Inertia rendering instead of Phoenix templates
      # This makes the sample Home page work out of the box
      controller_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "controllers",
          "page_controller.ex"
        ])

      if Igniter.exists?(igniter, controller_path) do
        igniter
        |> Igniter.include_existing_file(controller_path)
        |> Igniter.update_file(controller_path, fn source ->
          Rewrite.Source.update(source, :content, fn
            content when is_binary(content) ->
              # Check if already using Inertia
              if String.contains?(content, "render_inertia") do
                content
              else
                # Replace the home function to use NbInertia
                content
                |> String.replace(
                  ~r/def home\(conn, _params\) do\s*\n\s*render\(conn, :home\)\s*\n\s*end/,
                  """
                  def home(conn, _params) do
                      render_inertia(conn, "Home", greeting: "Welcome to Inertia.js!")
                    end
                  """,
                  global: false
                )
              end

            content ->
              content
          end)
        end)
      else
        igniter
      end
    end

    @doc false
    def create_lib_inertia(igniter) do
      client_framework = igniter.args.options[:client_framework]
      typescript = igniter.args.options[:typescript] || false

      case client_framework do
        "react" ->
          extension = if typescript, do: "ts", else: "js"
          content = lib_inertia_react_content()

          Igniter.create_new_file(igniter, "assets/js/lib/inertia.#{extension}", content,
            on_exists: :skip
          )

        "vue" ->
          extension = if typescript, do: "ts", else: "js"
          content = lib_inertia_vue_content()

          Igniter.create_new_file(igniter, "assets/js/lib/inertia.#{extension}", content,
            on_exists: :skip
          )

        _ ->
          igniter
      end
    end

    defp lib_inertia_react_content() do
      """
      // Enhanced Inertia.js integration with nb_routes support (React)
      //
      // This file re-exports enhanced components from nb_inertia that provide
      // automatic integration with nb_routes rich mode. Import from this file
      // instead of @inertiajs/react to get the enhanced functionality.
      //
      // Example:
      //   import { router, Link, useForm } from '@/lib/inertia';
      //   import { user_path } from '@/routes';
      //
      //   router.visit(user_path(1));           // Works with RouteResult objects
      //   <Link href={user_path(1)}>User</Link> // Works with RouteResult objects

      export { router } from '@nordbeam/nb-inertia/react/router';
      export { Link } from '@nordbeam/nb-inertia/react/Link';
      export { useForm } from '@nordbeam/nb-inertia/react/useForm';

      // Modal components
      export {
        Modal,
        HeadlessModal,
        ModalLink,
        ModalContent,
        SlideoverContent,
        CloseButton,
        ModalStackProvider,
        useModalStack,
        useModal
      } from '@nordbeam/nb-inertia/react/modals';

      // Re-export everything else from Inertia
      export * from '@inertiajs/react';
      """
    end

    defp lib_inertia_vue_content() do
      """
      // Enhanced Inertia.js integration with nb_routes support (Vue)
      //
      // This file re-exports enhanced components from nb_inertia that provide
      // automatic integration with nb_routes rich mode. Import from this file
      // instead of @inertiajs/vue3 to get the enhanced functionality.
      //
      // Example:
      //   import { router, Link, useForm } from '@/lib/inertia';
      //   import { user_path } from '@/routes';
      //
      //   router.visit(user_path(1));              // Works with RouteResult objects
      //   <Link :href="user_path(1)">User</Link>   // Works with RouteResult objects

      export { router } from '@nordbeam/nb-inertia/vue/router';
      export { default as Link } from '@nordbeam/nb-inertia/vue/Link';
      export { useForm } from '@nordbeam/nb-inertia/vue/useForm';

      // Modal components
      export {
        Modal,
        HeadlessModal,
        ModalLink,
        ModalContent,
        SlideoverContent,
        CloseButton,
        createModalStack,
        useModalStack,
        useModal,
        MODAL_STACK_KEY
      } from '@nordbeam/nb-inertia/vue/modals';

      // Re-export everything else from Inertia
      export * from '@inertiajs/vue3';
      """
    end

    @doc false
    def copy_modal_components(igniter) do
      # Only copy for React for now (Vue support can be added later)
      client_framework = igniter.args.options[:client_framework]

      if client_framework == "react" do
        priv_dir = :code.priv_dir(:nb_inertia)
        source_path = Path.join([priv_dir, "components", "modals"])
        dest_path = "assets/js/components/modals"

        # Modal component files to copy
        component_files = [
          "ModalStackRenderer.tsx",
          "index.ts"
        ]

        Enum.reduce(component_files, igniter, fn filename, acc ->
          source_file = Path.join(source_path, filename)
          dest_file = Path.join(dest_path, filename)

          if File.exists?(source_file) do
            content = File.read!(source_file)
            Igniter.create_new_file(acc, dest_file, content, on_exists: :skip)
          else
            acc
          end
        end)
      else
        igniter
      end
    end

    defp print_next_steps(igniter) do
      client_framework = igniter.args.options[:client_framework]
      typescript = igniter.args.options[:typescript] || false
      camelize_props = igniter.args.options[:camelize_props] || false
      history_encrypt = igniter.args.options[:history_encrypt] || false
      ssr_enabled = igniter.args.options[:ssr] || false
      with_flop = igniter.args.options[:with_flop] || false
      using_vite = using_nb_vite?(igniter)
      using_bun_runtime = using_bun?(igniter)
      pkg_manager = get_package_manager_command(igniter)

      config_items =
        [
          if(camelize_props, do: "\n  - camelize_props: true", else: nil),
          if(history_encrypt, do: "\n  - history: [encrypt: true]", else: nil),
          if(ssr_enabled && using_vite, do: "\n  - ssr: true", else: nil)
        ]
        |> Enum.filter(& &1)

      config_info =
        if Enum.any?(config_items) do
          "\n\nConfiguration added to config/config.exs under :nb_inertia:" <>
            Enum.join(config_items, "")
        else
          ""
        end

      bundler_info =
        if using_vite do
          "- Using nb_vite for asset bundling (with #{if using_bun_runtime, do: "Bun", else: "Node.js"})"
        else
          "- Configured esbuild for code splitting"
        end

      ssr_info =
        if ssr_enabled && using_vite do
          """

          SSR Configuration:
          - Added {:deno_rider, "~> 0.2"} for production SSR
          - Created SSR entry points:
            • assets/js/ssr.#{if typescript, do: "tsx", else: "jsx"} - Main SSR entry (used by Vite)
            • assets/js/ssr_prod.#{if typescript, do: "tsx", else: "jsx"} - Production SSR for Deno (eager loading)
          - Created Vite plugin for Deno compatibility
          - SSR enabled in nb_inertia config

          MANUAL SETUP REQUIRED:

          Note: Vite 6+ is required for SSR support.
          nb_vite uses Vite's built-in Module Runner API (no vite-node needed).

          1. Update your assets/vite.config.js to wrap the config in a function:

             import nodePrefixPlugin from './vite-plugins/node-prefix-plugin.js'

             export default defineConfig(({ command, mode, isSsrBuild }) => {
               const isSSR = isSsrBuild || process.env.BUILD_SSR === "true";

               if (isSSR) {
                 return {
                   plugins: [react(), nodePrefixPlugin()],
                   build: {
                     ssr: true,
                     outDir: "../priv/static",
                     rollupOptions: {
                       input: "js/ssr_prod.#{if typescript, do: "tsx", else: "jsx"}",
                       output: {
                         format: "esm",
                         entryFileNames: "ssr.js",
                         footer: "globalThis.render = render;",
                       },
                       external: (id) => id.startsWith('node:'),
                     },
                   },
                   resolve: { alias: { "@": path.resolve(__dirname, "./js") } },
                   ssr: { noExternal: true, target: "neutral" },
                 };
               }

               // Return your existing client config here...
               return { /* your existing config */ };
             });

          2. Add ssrDev to your phoenix plugin:
             phoenix({
               ...existing options...,
               ssrDev: {
                 enabled: true,
                 path: '/ssr',
                 healthPath: '/ssr-health',
                 entryPoint: './js/ssr.#{if typescript, do: "tsx", else: "jsx"}',
                 hotFile: '../priv/ssr-hot',
               },
             })

          3. Add build:ssr script to package.json:
             "build:ssr": "vite build --ssr"

          4. Build SSR bundle: #{pkg_manager} run build:ssr

          Development SSR is handled automatically by nb_vite ssrDev plugin.
          Production SSR uses DenoRider for optimal performance.
          """
        else
          ""
        end

      typescript_info =
        if typescript do
          """

          TypeScript Integration (nb_ts):
          - Added {:nb_ts, "~> 0.1"} for TypeScript type generation
          - Created types output directory at assets/js/types
          - Added mix alias: mix ts.gen (run after modifying props or serializers)
          - Will generate TypeScript interfaces for:
            • NbSerializer serializers
            • Inertia page props
          - Use the ~TS sigil for compile-time type validation in page props

          NOTE: Type generation is manual. Run 'mix ts.gen' after making changes to keep types in sync.
          """
        else
          ""
        end

      flop_info =
        if with_flop do
          """

          Flop Integration (nb_flop):
          - Added {:nb_flop, "~> 0.1"} and {:flop, "~> 0.26"} for pagination, sorting, and filtering
          - Generated Flop serializers to lib/your_app_web/serializers/
          - Copied React components to assets/js/components/flop/
          - Installed @tanstack/react-table

          Prerequisites for Flop components (shadcn/ui):
              npx shadcn@latest add button badge popover dropdown-menu command input

          Usage:
          1. Add @derive Flop.Schema to your Ecto schemas
          2. Use FlopMetaSerializer in your controllers:

             render_inertia(conn, :posts_index,
               posts: {PostSerializer, posts},
               meta: {FlopMetaSerializer, meta, schema: Post}
             )

          3. Use Flop components in your frontend:

             import { Pagination, FilterBar, DataTable } from '@/components/flop';
          """
        else
          ""
        end

      lib_inertia_info =
        if client_framework == "react" do
          extension = if typescript, do: "ts", else: "js"

          """

          Enhanced Inertia Components (React):
          - Created assets/js/lib/inertia.#{extension} with enhanced components
          - Re-exports router, Link, and useForm from @nordbeam/nb-inertia
          - Provides automatic integration with nb_routes rich mode
          - Also re-exports all standard Inertia.js exports for convenience

          IMPORTANT: Import from @/lib/inertia instead of @inertiajs/react:

            import { router, Link, useForm } from '@/lib/inertia';
            import { user_path } from '@/routes';

            // Works seamlessly with nb_routes RouteResult objects
            router.visit(user_path(1));
            <Link href={user_path(1)}>View User</Link>

          This gives you enhanced functionality while maintaining full backward
          compatibility with standard Inertia.js usage.

          Modal Components (shadcn/ui):
          - Copied ModalStackRenderer to assets/js/components/modals/
          - Uses shadcn Dialog (modals) and Sheet (slideovers)
          - Prerequisites: npx shadcn@latest add dialog sheet
          - Customize the renderer to match your app's design

          To enable modals, wrap your app:

            import { ModalStackProvider, InitialModalHandler } from '@/lib/inertia';
            import { ModalStackRenderer } from '@/components/modals';

            function App({ children }) {
              return (
                <ModalStackProvider resolveComponent={resolvePageComponent}>
                  <InitialModalHandler resolveComponent={resolvePageComponent} />
                  {children}
                  <ModalStackRenderer />
                </ModalStackProvider>
              );
            }
          """
        else
          if client_framework == "vue" do
            extension = if typescript, do: "ts", else: "js"

            """

            Enhanced Inertia Components (Vue):
            - Created assets/js/lib/inertia.#{extension} with enhanced components
            - Re-exports router, Link, and useForm from @nordbeam/nb-inertia
            - Provides automatic integration with nb_routes rich mode
            - Also re-exports all standard Inertia.js exports for convenience

            IMPORTANT: Import from @/lib/inertia instead of @inertiajs/vue3:

              import { router, Link, useForm } from '@/lib/inertia';
              import { user_path } from '@/routes';

              // Works seamlessly with nb_routes RouteResult objects
              router.visit(user_path(1));
              <Link :href="user_path(1)">View User</Link>

            This gives you enhanced functionality while maintaining full backward
            compatibility with standard Inertia.js usage.
            """
          else
            ""
          end
        end

      next_steps = """
      NbInertia has been successfully installed!

      What was configured:
      - Added {:nb_inertia, "~> 0.1"} and {:inertia, "~> 2.5"} to dependencies#{if typescript, do: "\n- Added {:nb_ts, \"~> 0.1\"} for TypeScript integration", else: ""}#{if with_flop, do: "\n- Added {:nb_flop, \"~> 0.1\"} and {:flop, \"~> 0.26\"} for pagination, sorting, and filtering", else: ""}
      - Set up controller helpers (use NbInertia.Controller)
      - Set up HTML helpers (import Inertia.HTML)
      - Added plug Inertia.Plug to the browser pipeline
      - Updated root layout for Inertia.js
      #{bundler_info}
      - Package manager: #{pkg_manager}#{config_info}
      - Installed #{client_framework} client packages#{if typescript, do: " with TypeScript", else: ""}
      - Created sample page component at assets/js/pages/Home.#{if typescript, do: "tsx", else: "jsx"}#{if client_framework in ["react", "vue"], do: "\n- Created assets/js/lib/inertia.#{if typescript, do: "ts", else: "js"} with enhanced components", else: ""}#{if client_framework == "react", do: "\n- Copied modal UI components to assets/js/components/modals/ (shadcn/ui based)", else: ""}#{typescript_info}#{flop_info}#{lib_inertia_info}#{ssr_info}

      Next steps:
      1. Create an Inertia-enabled controller action:

         defmodule MyAppWeb.PageController do
           use MyAppWeb, :controller
           use NbInertia.Controller#{if typescript, do: "\n           import NbTs.Sigil", else: ""}

           inertia_page :home do
             prop :greeting, #{if typescript, do: "type: ~TS\"string\"", else: ":string"}
           end

           def home(conn, _params) do
             render_inertia(conn, :home,
               greeting: "Hello from NbInertia!"
             )
           end
         end

      2. Add a route in your router:

         get "/", PageController, :home

      3. Create page components in assets/js/pages/
         - NbInertia automatically converts :home to "Home"
         - Use :users_index to render "Users/Index" component#{if typescript, do: "\n\n      4. Generate TypeScript types from your serializers and pages:\n\n         mix ts.gen\n\n      5. Import generated types in your React components:\n\n         import type { HomeProps } from \"@/types\";\n\n         export default function Home({ greeting }: HomeProps) {\n           return <h1>{greeting}</h1>;\n         }", else: ""}

      #{if typescript, do: "6", else: "4"}. Start your Phoenix server:

         mix phx.server

      For more information:
      - NbInertia docs: https://hexdocs.pm/nb_inertia
      - Inertia.js docs: https://inertiajs.com#{if typescript, do: "\n      - NbTs docs: https://hexdocs.pm/nb_ts", else: ""}#{if with_flop, do: "\n      - NbFlop docs: https://hexdocs.pm/nb_flop\n      - Flop docs: https://hexdocs.pm/flop", else: ""}
      """

      Igniter.add_notice(igniter, next_steps)
    end
  end
else
  defmodule Mix.Tasks.NbInertia.Install do
    @shortdoc "Install `igniter` in order to install NbInertia."

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'nb_inertia.install' requires igniter. Please install igniter and try again.

      Add to your mix.exs:

          {:igniter, "~> 0.5", only: [:dev]}

      Then run:

          mix deps.get
          mix nb_inertia.install

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
