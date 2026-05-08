defmodule Mix.Tasks.NbInertia.InstallTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.NbInertia.Install

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
