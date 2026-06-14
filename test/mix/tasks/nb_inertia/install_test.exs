defmodule Mix.Tasks.NbInertia.InstallTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.NbInertia.Install
  import Igniter.Test, only: [apply_igniter!: 1, test_project: 1]

  defp put_options(igniter, options) do
    %{igniter | args: %{igniter.args | options: Keyword.merge(igniter.args.options, options)}}
  end

  defp project_root do
    Path.expand("../../../../", __DIR__)
  end

  defp generated_installer_assets!(client_framework) do
    test_project(app_name: :sample)
    |> put_options(client_framework: client_framework, typescript: true)
    |> Install.setup_client()
    |> Install.create_lib_inertia()
    |> apply_igniter!()
    |> then(& &1.assigns.test_files)
  end

  defp run_command!(command, args, opts) do
    {output, status} =
      System.cmd(command, args, Keyword.merge([stderr_to_stdout: true], opts))

    assert status == 0, """
    expected #{Enum.join([command | args], " ")} to exit successfully

    Output:
    #{output}
    """

    output
  end

  defp npm_pack!(tmp_dir) do
    output =
      run_command!("npm", ["pack", "--silent", "--pack-destination", tmp_dir], cd: project_root())

    Path.join(tmp_dir, String.trim(output))
  end

  defp assert_generated_barrel_compiles!(
         tmp_dir,
         package_tarball,
         client_framework,
         deps,
         checker
       ) do
    files = generated_installer_assets!(client_framework)
    assets_dir = Path.join([tmp_dir, client_framework, "assets"])

    File.mkdir_p!(Path.join([assets_dir, "js", "lib"]))

    File.write!(
      Path.join([assets_dir, "js", "lib", "inertia.ts"]),
      files["assets/js/lib/inertia.ts"]
    )

    File.write!(Path.join(assets_dir, "tsconfig.json"), files["assets/tsconfig.json"])

    run_command!("npm", ["init", "-y"], cd: assets_dir)

    run_command!(
      "npm",
      [
        "install",
        "--silent",
        "--no-audit",
        "--fund=false",
        "--package-lock=false",
        package_tarball
        | deps
      ],
      cd: assets_dir
    )

    run_command!("npx", ["--no-install", checker, "--noEmit", "--pretty", "false"],
      cd: assets_dir
    )
  end

  describe "info/2" do
    test "declares optional deps and composed installers for requested integrations" do
      info = Install.info(["--typescript", "--with-flop", "--table"], nil)

      assert info.adds_deps == [
               {:nb_ts, github: "nordbeam/nb_ts"},
               {:nb_flop, github: "nordbeam/nb_flop"}
             ]

      assert info.composes == ["nb_ts.install", "nb_flop.install"]
    end

    test "adds deno_rider whenever SSR is requested" do
      options = Install.installer_options(["--ssr"])

      assert Install.optional_dependency_specs(options, [:nb_vite]) == [
               {:deno_rider, "~> 0.2"}
             ]

      assert Install.optional_dependency_specs(options, []) == [
               {:deno_rider, "~> 0.2"}
             ]
    end

    test "parses grouped igniter flags for shared nb task namespaces" do
      info = Install.info(["--nb.typescript", "--nb.with-flop"], nil)

      assert info.adds_deps == [
               {:nb_ts, github: "nordbeam/nb_ts"},
               {:nb_flop, github: "nordbeam/nb_flop"}
             ]
    end

    test "installer contract exposes controller and React/Vue options without Page-module mode" do
      info = Install.info(["--client-framework", "vue"], nil)
      options = Install.installer_options(["--client-framework", "vue"])

      assert info.schema[:client_framework] == :string
      assert options[:client_framework] == "vue"
      refute Keyword.has_key?(info.schema, :pages)
      refute Keyword.has_key?(options, :pages)
    end

    test "skips companion deps that are already installed" do
      options = Install.installer_options(["--typescript", "--with-flop"])

      assert Install.optional_dependency_specs(options, [:nb_ts, :nb_flop]) == []
    end

    test "full mode declares the complete stack installer contract" do
      info = Install.info(["--full"], nil)
      options = Install.installer_options(["--full"]) |> Install.effective_options()

      assert info.composes == [
               "nb_vite.install",
               "nb_serializer.install",
               "nb_ts.install",
               "nb_flop.install"
             ]

      assert Install.optional_dependency_specs(options, []) == [
               {:nb_vite, github: "nordbeam/nb_vite", override: true},
               {:nb_routes, github: "nordbeam/nb_routes", override: true},
               {:nb_serializer, github: "nordbeam/nb_serializer", override: true},
               {:nb_ts, github: "nordbeam/nb_ts"},
               {:nb_flop, github: "nordbeam/nb_flop"},
               {:deno_rider, "~> 0.2"}
             ]
    end
  end

  describe "effective_options/1" do
    test "full mode enables the nb_stack defaults on nb_inertia" do
      options =
        ["--full"]
        |> Install.installer_options()
        |> Install.effective_options()

      assert options[:full] == true
      assert options[:client_framework] == "react"
      assert options[:camelize_props] == true
      assert options[:typescript] == true
      assert options[:ssr] == true
      assert options[:with_flop] == true
      assert options[:table] == true
    end
  end

  describe "npm_source_from_dep_declaration/2" do
    test "falls back to the github source when nb_inertia is installed from path" do
      source =
        Install.npm_source_from_dep_declaration(
          "{:nb_inertia, [path: \"../nb_inertia\", override: true]}",
          "github:nordbeam/nb_inertia"
        )

      assert source == "github:nordbeam/nb_inertia"
    end

    test "preserves github refs when nb_inertia is installed from github" do
      source =
        Install.npm_source_from_dep_declaration(
          "{:nb_inertia, [github: \"nordbeam/nb_inertia\", ref: \"abc123\"]}",
          "github:nordbeam/nb_inertia"
        )

      assert source == "github:nordbeam/nb_inertia#abc123"
    end

    test "falls back to the default source for version-only deps" do
      assert Install.npm_source_from_dep_declaration(
               "{:nb_inertia, \"~> 1.0\"}",
               "github:nordbeam/nb_inertia"
             ) == "github:nordbeam/nb_inertia"
    end
  end

  describe "forwarded_global_argv/1" do
    test "keeps only child-safe confirmation flags" do
      assert Install.forwarded_global_argv([
               "--yes",
               "--verbose",
               "--only",
               "dev",
               "--client-framework",
               "react",
               "--typescript"
             ]) == ["--yes"]
    end
  end

  describe "generated controller migration" do
    test "renames stock Phoenix controller files to HomeController files" do
      stock_controller = "Page" <> "Controller"

      igniter =
        test_project(
          app_name: :sample,
          files: %{
            "lib/sample_web/controllers/page_controller.ex" => """
            defmodule SampleWeb.#{stock_controller} do
              use SampleWeb, :controller

              def home(conn, _params) do
                render(conn, :home)
              end
            end
            """,
            "test/sample_web/controllers/page_controller_test.exs" => """
            defmodule SampleWeb.#{stock_controller}Test do
              use SampleWeb.ConnCase

              test "GET /", %{conn: conn} do
                conn = get(conn, ~p"/")
                assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
              end
            end
            """
          }
        )
        |> Install.update_home_controller()
        |> Install.update_home_controller_test()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      refute Map.has_key?(files, "lib/sample_web/controllers/page_controller.ex")
      refute Map.has_key?(files, "test/sample_web/controllers/page_controller_test.exs")

      assert home_controller = files["lib/sample_web/controllers/home_controller.ex"]
      assert home_controller =~ "defmodule SampleWeb.HomeController do"
      assert home_controller =~ "inertia_page :home do"

      assert home_controller =~
               ~S|render_inertia_page(conn, :home, greeting: "Welcome to Inertia.js!")|

      assert home_controller_test = files["test/sample_web/controllers/home_controller_test.exs"]
      assert home_controller_test =~ "defmodule SampleWeb.HomeControllerTest do"
      assert home_controller_test =~ ~S|assert html_response(conn, 200) =~ ~s(data-page="app")|
    end
  end

  describe "transform_vite_config_for_ssr/2" do
    test "wraps generated vite config in SSR-aware defineConfig and injects ssrDev" do
      vite_config = """
      import { defineConfig } from 'vite'
      import phoenix from '@nordbeam/nb-vite'
      import path from 'path'
      import react from '@vitejs/plugin-react'

      export default defineConfig({
        plugins: [
          react({
            babel: {
              plugins: ['babel-plugin-react-compiler'],
            },
          }),
          phoenix({
            input: ['js/app.ts', 'js/app.tsx', 'css/app.css'],
            publicDirectory: '../priv/static',
            buildDirectory: 'assets',
            hotFile: '../priv/hot',
            manifestPath: '../priv/static/assets/manifest.json',
            refresh: true,
          })
        ],
        server: {
          host: process.env.VITE_HOST || "127.0.0.1",
          port: parseInt(process.env.VITE_PORT || "5173"),
        },
        resolve: {
          alias: {
            '@': path.resolve(__dirname, './js')
          }
        }
      })
      """

      assert {:ok, transformed} = Install.transform_vite_config_for_ssr(vite_config, "tsx")

      assert transformed =~
               "import nodePrefixPlugin from './vite-plugins/node-prefix-plugin.js'"

      assert transformed =~
               "export default defineConfig(({ command, mode, isSsrBuild }) => {"

      assert transformed =~ ~s(const isSSR = isSsrBuild || process.env.BUILD_SSR === "true";)
      assert transformed =~ ~s(input: "js/ssr_prod.tsx")
      assert transformed =~ "entryPoint: './js/ssr.tsx'"
      assert transformed =~ "nodePrefixPlugin()"
    end
  end

  describe "create_lib_inertia/1" do
    test "React + TypeScript generates assets/js/lib/inertia.ts with nb-inertia/react exports" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "react", typescript: true)
        |> Install.create_lib_inertia()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      assert lib_ts = files["assets/js/lib/inertia.ts"]
      assert lib_ts =~ "@nordbeam/nb-inertia/react/useForm"
      assert lib_ts =~ "@nordbeam/nb-inertia/react/useFlash"
      assert lib_ts =~ "@nordbeam/nb-inertia/react/modals"
      assert lib_ts =~ "export * from '@inertiajs/react'"
      refute Map.has_key?(files, "assets/js/lib/inertia.js")
    end

    test "React without TypeScript generates assets/js/lib/inertia.js" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "react", typescript: false)
        |> Install.create_lib_inertia()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      assert Map.has_key?(files, "assets/js/lib/inertia.js")
      refute Map.has_key?(files, "assets/js/lib/inertia.ts")
    end

    test "Vue + TypeScript generates assets/js/lib/inertia.ts with nb-inertia/vue exports" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "vue", typescript: true)
        |> Install.create_lib_inertia()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      assert lib_ts = files["assets/js/lib/inertia.ts"]
      assert lib_ts =~ "@nordbeam/nb-inertia/vue/useForm"
      assert lib_ts =~ "@nordbeam/nb-inertia/vue/useFlash"
      assert lib_ts =~ "@nordbeam/nb-inertia/vue/modals"
      assert lib_ts =~ "export * from '@inertiajs/vue3'"
      refute Map.has_key?(files, "assets/js/lib/inertia.js")
    end

    test "Vue without TypeScript generates assets/js/lib/inertia.js" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "vue", typescript: false)
        |> Install.create_lib_inertia()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      assert Map.has_key?(files, "assets/js/lib/inertia.js")
      refute Map.has_key?(files, "assets/js/lib/inertia.ts")
    end

    test "unsupported framework creates no lib/inertia file" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "svelte", typescript: true)
        |> Install.create_lib_inertia()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      refute Map.has_key?(files, "assets/js/lib/inertia.ts")
      refute Map.has_key?(files, "assets/js/lib/inertia.js")
    end
  end

  describe "Vue modal dependency installation" do
    test "Vue install command includes radix-vue for modal components" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "vue", typescript: true)
        |> Install.setup_client()

      cmd_tasks =
        Enum.filter(igniter.tasks, fn
          {"cmd", _} -> true
          {"cmd", _, _} -> true
          _ -> false
        end)

      assert Enum.any?(cmd_tasks, fn {"cmd", [cmd | _]} ->
               String.contains?(cmd, "radix-vue")
             end)
    end
  end

  describe "copy_modal_components/1" do
    test "React copies ModalStackRenderer and index to assets/js/components/modals/" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "react", typescript: true)
        |> Install.copy_modal_components()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      assert Map.has_key?(files, "assets/js/components/modals/ModalStackRenderer.tsx")
      assert Map.has_key?(files, "assets/js/components/modals/index.ts")
    end

    test "Vue does not copy local modal files — modals come from the npm package" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "vue", typescript: true)
        |> Install.copy_modal_components()
        |> apply_igniter!()

      files = igniter.assigns.test_files

      refute Enum.any?(Map.keys(files), &String.contains?(&1, "modals/ModalStackRenderer"))
    end
  end

  describe "lib/inertia template content" do
    test "React template exports all named modal components from nb-inertia/react/modals" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "ModalStackProvider"
      assert source =~ "InitialModalHandler"
      assert source =~ "ModalLink"
      assert source =~ "HeadlessModal"
      assert source =~ "from '@nordbeam/nb-inertia/react/modals'"
    end

    test "Vue template exports modal components from nb-inertia/vue/modals" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "createModalStack"
      assert source =~ "useModalStack"
      assert source =~ "from '@nordbeam/nb-inertia/vue/modals'"
    end

    test "React template exports from @inertiajs/react not @inertiajs/vue3" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "export * from '@inertiajs/react'"
    end

    test "Vue template exports from @inertiajs/vue3 not @inertiajs/react" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "export * from '@inertiajs/vue3'"
    end

    test "Vue template re-exports Head as default alias to match package export shape" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "export { default as Head } from '@nordbeam/nb-inertia/vue/Head'"
      refute source =~ "export { Head } from '@nordbeam/nb-inertia/vue/Head'"
    end

    test "Vue template documents radix-vue as auto-installed modal dependency" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "radix-vue is installed automatically"
    end
  end

  describe "SSR entry templates" do
    test "SSR dev template uses createInertiaApp from @/lib/inertia" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ ~s(import { createInertiaApp } from "@/lib/inertia";)
      assert source =~ "ReactDOMServer.renderToString"
      assert source =~ "export async function render(page"
    end

    test "SSR prod template uses eager glob for Deno compatibility" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ ~S|import.meta.glob<PageModule>("./pages/**/*.tsx", { eager: true })|
      assert source =~ "return pages[pagePath].default"
    end

    test "SSR healthcheck guard is present in both dev and prod templates" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ ~s(page?.component === "__nb_inertia_healthcheck__")
    end
  end

  describe "Svelte not advertised" do
    test "installer docs do not list svelte as a supported framework" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      refute source =~ "(react, vue, or svelte)"
      assert source =~ "(react or vue)"
    end

    test "svelte framework option triggers a warning, not a silent partial install" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "Svelte integration is not supported by nb_inertia"
    end

    test "setup_client with svelte queues no cmd tasks" do
      igniter =
        test_project(app_name: :sample)
        |> put_options(client_framework: "svelte", typescript: true)
        |> Install.setup_client()

      refute Enum.any?(igniter.tasks, fn
               {"cmd", _} -> true
               {"cmd", _, _} -> true
               _ -> false
             end)
    end
  end

  describe "no removed Page APIs in installer output" do
    test "next-steps controller example uses inertia_page DSL and render_inertia_page" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "inertia_page :home do"
      assert source =~ "render_inertia_page(conn, :home,"
      refute source =~ "NbInertia.Page"
      refute source =~ "use NbInertia.Page"
    end

    test "Vue next-steps mention modal components via the npm package, not file copy" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~ "Modal components are delivered via @nordbeam/nb-inertia/vue/modals"
      assert source =~ "No local file copy required"
      assert source =~ "createModalStack"
    end

    test "React next-steps mention copying modal UI components" do
      source =
        Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
        |> File.read!()

      assert source =~
               "Copied modal UI components to assets/js/components/modals/ (shadcn/ui based)"

      assert source =~ "Modal Components (shadcn/ui)"
    end
  end

  test "hex package includes installer assets" do
    assert "priv" in Mix.Project.config()[:package][:files]
  end

  test "installer source uses Inertia HTTP hooks for CSRF instead of axios" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~ ~s(import { createInertiaApp, http } from "@/lib/inertia";)
    assert source =~ "http.onRequest((config) => {"
    refute source =~ "axios.defaults.xsrfHeaderName"
  end

  test "installer TypeScript templates include Vite and typed SSR module support" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~ ~s("types": ["vite/client"])
    refute source =~ ~s("baseUrl": ".")
    assert source =~ ~s("js/app.tsx")
    refute source =~ ~s("include": ["js/**/*.ts", "js/**/*.tsx", "js/**/*.js", "js/**/*.jsx"])
    assert source =~ ~s("@/types": ["./js/types/index"])
    assert source =~ ~s(import type { ComponentType } from "react";)
    assert source =~ ~S|import.meta.glob<PageModule>("./pages/**/*.tsx")|
    assert source =~ "return pageModule.default"
    assert source =~ "return pages[pagePath].default"
  end

  test "full installer demo inlines contact form types into HomeProps" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~ ~s(import type { HomeProps } from "@/types";)
    assert source =~ ~s(const form = useForm<HomeProps["contactForm"]>()
    assert source =~ "prop :contact_form, :map, default: %{}"
    assert source =~ "prop :items, list_of(ref(ItemSerializer))"
    refute source =~ ~s(import type { HomeProps, HomeFormInputs } from "@/types";)
    refute source =~ ~s(useForm<HomeFormInputs["contactForm"]>)
  end

  test "full installer demo emits valid nested interpolation in contact flash" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~
             ~S|inertia_flash(:success, "Thanks, \#{params["name"]}! We got your message.")|

    refute source =~ ~S|params[\\"name\\"]|
  end

  test "installer snippets prefer canonical shared props and serializer helpers" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~ "render_inertia_page(conn, :page_name, props)"
    assert source =~ "render_inertia_page(conn, :posts_index,"

    assert source =~
             "render_inertia_page(conn, :home, [greeting: \"Hello from NbInertia!\"], ssr: true)"

    assert source =~ "include_shared_props(DemoShared)"
    assert source =~ "items: serialize(ItemSerializer, @items)"
    assert source =~ "meta: serialize(FlopMetaSerializer, meta)"
    assert source =~ "posts: serialize(PostSerializer, posts)"
    assert source =~ "meta: serialize(FlopMetaSerializer, meta, opts: [schema: Post])"
    assert source =~ "Register shared props modules with include_shared_props/2"
    refute source =~ "render_inertia(conn, :page_name, props)"
    refute source =~ "render_inertia(conn, :posts_index,"
    refute source =~ "render_inertia(conn, :home,"
    refute source =~ "inertia_shared(DemoShared)"
    refute source =~ "items: {ItemSerializer, @items}"
    refute source =~ "meta: {FlopMetaSerializer, meta}"
    refute source =~ "posts: {PostSerializer, posts}"
    refute source =~ "meta: {FlopMetaSerializer, meta, schema: Post}"
  end

  describe "vue/modals npm package export type compatibility" do
    test "package.json ./vue/modals lists the types condition before the runtime import" do
      package_json =
        Path.expand("../../../../package.json", __DIR__)
        |> File.read!()

      assert package_json =~
               ~r/"\.\/vue\/modals":\s*\{\s*"types":\s*"[^"]+index\.d\.ts",\s*"import":\s*"[^"]+index\.js"\s*\}/s
    end

    test "package.json ./vue/modals types entry points to a .d.ts file, not raw .ts source" do
      package_json =
        Path.expand("../../../../package.json", __DIR__)
        |> File.read!()
        |> Jason.decode!()

      vue_modals = get_in(package_json, ["exports", "./vue/modals"])

      assert vue_modals != nil, "expected ./vue/modals export to be defined"

      assert String.ends_with?(vue_modals["types"], ".d.ts"),
             "expected ./vue/modals types to be a .d.ts file so vue-tsc can resolve it " <>
               "without allowArbitraryExtensions; got: #{vue_modals["types"]}"
    end

    test "package.json ./vue/modals import entry points to a .js file so vue-tsc uses types condition" do
      package_json =
        Path.expand("../../../../package.json", __DIR__)
        |> File.read!()
        |> Jason.decode!()

      vue_modals = get_in(package_json, ["exports", "./vue/modals"])

      assert vue_modals != nil, "expected ./vue/modals export to be defined"

      assert String.ends_with?(vue_modals["import"], ".js"),
             "expected ./vue/modals import to be a .js file — a .ts import entry causes " <>
               "vue-tsc to process the source and fail on .vue SFC re-exports with TS2305; " <>
               "got: #{vue_modals["import"]}"
    end

    test "dist/vue/modals/index.js exists as the bundler-facing runtime entry" do
      index_js = Path.expand("../../../../dist/vue/modals/index.js", __DIR__)

      assert File.exists?(index_js),
             "expected dist/vue/modals/index.js to exist as the bundler-facing runtime entry " <>
               "for consumers using Vite + @vitejs/plugin-vue"
    end

    test "vue/modals index.d.ts exists and declares components without .vue file imports" do
      index_dts_path = Path.expand("../../../../priv/nb_inertia/vue/modals/index.d.ts", __DIR__)

      assert File.exists?(index_dts_path),
             "expected priv/nb_inertia/vue/modals/index.d.ts to exist for vue-tsc compatibility"

      index_dts = File.read!(index_dts_path)

      assert index_dts =~ "createModalStack"
      assert index_dts =~ "useModalStack"
      assert index_dts =~ "MODAL_STACK_KEY"
      assert index_dts =~ "Modal"
      assert index_dts =~ "ModalLink"
      assert index_dts =~ "ModalConfig"

      refute index_dts =~ "from './Modal.vue'",
             "index.d.ts must not import .vue files — those require allowArbitraryExtensions"

      refute index_dts =~ "from './HeadlessModal.vue'"
      refute index_dts =~ "from './ModalLink.vue'"
    end
  end

  describe "packed TypeScript installer smoke tests" do
    @tag timeout: 180_000
    test "generated React and Vue lib/inertia barrels compile against packed package exports" do
      assert System.find_executable("npm") != nil,
             "npm is required for packed installer smoke tests"

      assert System.find_executable("npx") != nil,
             "npx is required for packed installer smoke tests"

      tmp_dir =
        Path.join(
          System.tmp_dir!(),
          "nb_inertia_installer_smoke_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(tmp_dir)

      on_exit(fn -> File.rm_rf(tmp_dir) end)

      package_tarball = npm_pack!(tmp_dir)

      assert_generated_barrel_compiles!(
        tmp_dir,
        package_tarball,
        "react",
        [
          "@inertiajs/react@^3.0.3",
          "react@^19.0.0",
          "react-dom@^19.0.0",
          "@radix-ui/react-visually-hidden",
          "@types/react",
          "@types/react-dom",
          "typescript",
          "vite"
        ],
        "tsc"
      )

      assert_generated_barrel_compiles!(
        tmp_dir,
        package_tarball,
        "vue",
        [
          "@inertiajs/vue3@^3.0.3",
          "vue@^3.0.0",
          "vue-loader",
          "radix-vue@^1.9.0",
          "@vue/compiler-sfc",
          "vue-tsc",
          "typescript",
          "vite"
        ],
        "vue-tsc"
      )
    end
  end

  test "installer next-step text avoids stale versioned deps and ~TS string guidance" do
    source =
      Path.expand("../../../../lib/mix/tasks/nb_inertia.install.ex", __DIR__)
      |> File.read!()

    assert source =~ "- Added nb_inertia to dependencies"
    assert source =~ "- Wired NbInertia.Controller into your Phoenix controller helper"
    assert source =~ "- Imported NbInertia.HTML into your Phoenix HTML helper"
    assert source =~ "prop :greeting, :string"
    refute source =~ ~s(- Added {:nb_inertia, "~> 0.4"} to dependencies)
    refute source =~ ~s(- Added {:nb_ts, "~> 0.1"} for TypeScript type generation)

    refute source =~
             ~s(- Added {:nb_flop, "~> 0.1"} and {:flop, "~> 0.26"} for pagination, sorting, and filtering)

    refute source =~ ~s(- Added {:deno_rider, "~> 0.2"} for production SSR)
    refute source =~ ~s(prop :greeting, type: ~TS"string")
    refute source =~ "Use the ~TS sigil for compile-time type validation in page props"
    refute source =~ "import NbTs.Sigil"
    refute source =~ ~s(prop :env, type: ~TS"'dev' | 'prod' | 'test'")
    assert source =~ ~s|prop :env, enum(["dev", "prod", "test"])|
  end
end
