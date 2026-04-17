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
end
