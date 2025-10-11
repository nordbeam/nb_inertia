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
    3. Sets up controller helpers (use NbInertia.Controller)
    4. Sets up HTML helpers (import Inertia.HTML)
    5. Adds `plug Inertia.Plug` to the browser pipeline
    6. Adds configuration to config/config.exs under :nb_inertia namespace
    7. Updates root layout template (with nb_vite support if detected)
    8. Configures asset bundler (esbuild by default, or skips if nb_vite is present)
    9. Detects and uses appropriate package manager (npm, yarn, pnpm, or bun)
    10. Creates sample Inertia page component
    11. Prints helpful next steps

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
        schema: [
          client_framework: :string,
          camelize_props: :boolean,
          history_encrypt: :boolean,
          typescript: :boolean,
          ssr: :boolean,
          yes: :boolean
        ],
        example: __MODULE__.Docs.example(),
        defaults: [client_framework: "react"],
        positional: [],
        composes: ["deps.get"]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> add_dependencies()
      |> setup_controller_helpers()
      |> setup_html_helpers()
      |> setup_router()
      |> add_inertia_config()
      |> update_root_layout()
      |> maybe_update_asset_bundler_config()
      |> setup_client()
      |> maybe_setup_ssr()
      |> create_sample_page()
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

      # Add inertia dependency (nb_inertia is already added by igniter.install)
      igniter = Igniter.Project.Deps.add_dep(igniter, {:inertia, "~> 2.5"})

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
      Igniter.Libs.Phoenix.append_to_pipeline(igniter, :browser, "plug Inertia.Plug")
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
    def update_root_layout(igniter) do
      file_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "components",
          "layouts",
          "root.html.heex"
        ])

      content =
        if using_nb_vite?(igniter) do
          inertia_root_html_vite()
        else
          inertia_root_html_esbuild()
        end

      Igniter.create_new_file(igniter, file_path, content, on_exists: :overwrite)
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

    defp inertia_root_html_vite() do
      """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="csrf-token" content={get_csrf_token()} />
          <.inertia_title><%= assigns[:page_title] %></.inertia_title>
          <.inertia_head content={@inertia_head} />
          <%= NbVite.vite_client() %>
          <%= NbVite.react_refresh() %>
          <%= NbVite.vite_assets("js/app.tsx") %>
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
      |> maybe_install_typescript_deps(client_framework, typescript)
    end

    defp install_client_main_packages(igniter, "react") do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" -> "cd assets && bun add @inertiajs/react react react-dom axios"
          "pnpm" -> "pnpm add --dir assets @inertiajs/react react react-dom axios"
          "yarn" -> "cd assets && yarn add @inertiajs/react react react-dom axios"
          _ -> "npm install --prefix assets @inertiajs/react react react-dom axios"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp install_client_main_packages(igniter, "vue") do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" -> "cd assets && bun add @inertiajs/vue3 vue vue-loader axios"
          "pnpm" -> "pnpm add --dir assets @inertiajs/vue3 vue vue-loader axios"
          "yarn" -> "cd assets && yarn add @inertiajs/vue3 vue vue-loader axios"
          _ -> "npm install --prefix assets @inertiajs/vue3 vue vue-loader axios"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp install_client_main_packages(igniter, "svelte") do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" -> "cd assets && bun add @inertiajs/svelte svelte axios"
          "pnpm" -> "pnpm add --dir assets @inertiajs/svelte svelte axios"
          "yarn" -> "cd assets && yarn add @inertiajs/svelte svelte axios"
          _ -> "npm install --prefix assets @inertiajs/svelte svelte axios"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_typescript_deps(igniter, _, false), do: igniter

    defp maybe_install_typescript_deps(igniter, "react", true) do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" ->
            "cd assets && bun add --dev @types/react @types/react-dom typescript"

          "pnpm" ->
            "pnpm add --dir assets --save-dev @types/react @types/react-dom typescript"

          "yarn" ->
            "cd assets && yarn add --dev @types/react @types/react-dom typescript"

          _ ->
            "npm install --prefix assets --save-dev @types/react @types/react-dom typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_typescript_deps(igniter, "vue", true) do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" -> "cd assets && bun add --dev @vue/compiler-sfc vue-tsc typescript"
          "pnpm" -> "pnpm add --dir assets --save-dev @vue/compiler-sfc vue-tsc typescript"
          "yarn" -> "cd assets && yarn add --dev @vue/compiler-sfc vue-tsc typescript"
          _ -> "npm install --prefix assets --save-dev @vue/compiler-sfc vue-tsc typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp maybe_install_typescript_deps(igniter, "svelte", true) do
      pkg_manager = get_package_manager_command(igniter)

      install_cmd =
        case pkg_manager do
          "bun" -> "cd assets && bun add --dev svelte-loader svelte-preprocess typescript"
          "pnpm" -> "pnpm add --dir assets --save-dev svelte-loader svelte-preprocess typescript"
          "yarn" -> "cd assets && yarn add --dev svelte-loader svelte-preprocess typescript"
          _ -> "npm install --prefix assets --save-dev svelte-loader svelte-preprocess typescript"
        end

      Igniter.add_task(igniter, "cmd", [install_cmd])
    end

    defp react_tsconfig_json() do
      """
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

    defp inertia_app_jsx(_igniter) do
      # The app.jsx/tsx file is the same for both esbuild and Vite
      # Vite natively handles JSX/TSX, esbuild is configured to handle it too
      """
      import React from "react";
      import axios from "axios";

      import { createInertiaApp } from "@inertiajs/react";
      import { createRoot } from "react-dom/client";

      axios.defaults.xsrfHeaderName = "x-csrf-token";

      createInertiaApp({
        resolve: async (name) => {
          return await import(`./pages/${name}.jsx`);
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
        |> add_ssr_config()
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
      |> Igniter.create_new_file("assets/js/ssr_dev.#{extension}", ssr_dev_template(),
        on_exists: :skip
      )
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
        {:code, Sourceror.parse_string!("[enabled: true]")}
      )
    end

    defp ssr_dev_template() do
      """
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
                `❌ SSR Page Not Found\\n\\n` +
                `Component: ${name}\\n` +
                `Expected file: assets/js/pages/${name}.tsx\\n\\n` +
                `This page file doesn't exist or wasn't found by Vite's glob.\\n\\n` +
                `Common causes:\\n` +
                `• The file hasn't been created yet\\n` +
                `• The file name doesn't match the component name\\n` +
                `• The file has the wrong extension (e.g., .tsxx instead of .tsx)\\n` +
                `• The component name in your controller doesn't match the file path\\n\\n` +
                `Available pages (${availablePages.length}):\\n` +
                availablePages.map(p => `  - ${p}`).join('\\n')
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
      """
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
                `❌ SSR Page Not Found\\n\\n` +
                `Component: ${name}\\n` +
                `Expected file: assets/js/pages/${name}.tsx\\n\\n` +
                `This page file doesn't exist or wasn't bundled in the SSR build.\\n\\n` +
                `Common causes:\\n` +
                `• The file hasn't been created yet\\n` +
                `• The file name doesn't match the component name\\n` +
                `• The file has the wrong extension (e.g., .tsxx instead of .tsx)\\n` +
                `• The component name in your controller doesn't match the file path\\n` +
                `• The SSR bundle needs to be rebuilt (run: bun build:ssr)\\n\\n` +
                `Available pages (${availablePages.length}):\\n` +
                availablePages.map(p => `  - ${p}`).join('\\n')
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

    defp print_next_steps(igniter) do
      client_framework = igniter.args.options[:client_framework]
      typescript = igniter.args.options[:typescript] || false
      camelize_props = igniter.args.options[:camelize_props] || false
      history_encrypt = igniter.args.options[:history_encrypt] || false
      ssr_enabled = igniter.args.options[:ssr] || false
      using_vite = using_nb_vite?(igniter)
      using_bun_runtime = using_bun?(igniter)
      pkg_manager = get_package_manager_command(igniter)

      config_info =
        config_items =
        [
          if(camelize_props, do: "\n  - camelize_props: true", else: nil),
          if(history_encrypt, do: "\n  - history: [encrypt: true]", else: nil),
          if(ssr_enabled && using_vite, do: "\n  - ssr: [enabled: true]", else: nil)
        ]
        |> Enum.filter(& &1)

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
            • assets/js/ssr_dev.#{if typescript, do: "tsx", else: "jsx"} - Development SSR with HMR
            • assets/js/ssr_prod.#{if typescript, do: "tsx", else: "jsx"} - Production SSR for Deno
          - Created Vite plugin for Deno compatibility
          - SSR enabled in nb_inertia config

          SSR Build Commands (add these to your vite.config.js and package.json):
          1. Update your vite.config.js to include SSR config
          2. Add build script to package.json:
             "build:ssr": "vite build --ssr"
          3. Build SSR bundle for production:
             #{pkg_manager} run build:ssr

          Development SSR is handled automatically by the nb_vite ssrDev plugin.
          Production SSR uses DenoRider for optimal performance.
          """
        else
          ""
        end

      next_steps = """
      NbInertia has been successfully installed!

      What was configured:
      - Added {:nb_inertia, "~> 0.1"} and {:inertia, "~> 2.5"} to dependencies
      - Set up controller helpers (use NbInertia.Controller)
      - Set up HTML helpers (import Inertia.HTML)
      - Added plug Inertia.Plug to the browser pipeline
      - Updated root layout for Inertia.js
      #{bundler_info}
      - Package manager: #{pkg_manager}#{config_info}
      - Installed #{client_framework} client packages#{if typescript, do: " with TypeScript", else: ""}
      - Created sample page component at assets/js/pages/Home.#{if typescript, do: "tsx", else: "jsx"}#{ssr_info}

      Next steps:
      1. Create an Inertia-enabled controller action:

         defmodule MyAppWeb.PageController do
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
         end

      2. Add a route in your router:

         get "/", PageController, :home

      3. Create page components in assets/js/pages/
         - NbInertia automatically converts :home to "Home"
         - Use :users_index to render "Users/Index" component

      4. Start your Phoenix server:

         mix phx.server

      For more information:
      - NbInertia docs: https://hexdocs.pm/nb_inertia
      - Inertia.js docs: https://inertiajs.com
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
