---
name: nb-inertia
description: "Implement, configure, upgrade, diagnose, and verify nb_inertia Phoenix integrations with typed pages, shared props, SSR, modals, and real-time features."
---

# NbInertia

Use this skill for `nb_inertia` controller/page contracts, Inertia rendering, shared props, lazy/partial/deferred data, SSR, modal/slideover flows, real-time updates, frontend adapters, or its optional package integrations.

## Discover the target release

- Inspect the target app's `mix.exs`, `mix.lock`, `assets/package.json` and lockfile, Phoenix web helpers/router, Vite/esbuild configuration, `config/config.exs`, `config/runtime.exs`, and generated frontend entry files. Read the selected README, `lib/mix/tasks/nb_inertia.install.ex`, and the relevant source modules before choosing an API.
- Treat `nb_serializer`, `nb_ts`, `nb_routes`, `nb_flop`, DenoRider, and client packages as optional integrations unless the target release explicitly makes them required. Do not add reverse or unconditional dependencies merely because another package is present.
- If release notes or docs label capabilities as Pitch 1 or Pitch 3, detect the installed version's modules, exports, installer flags, and generated files before using them. Describe an absent capability as unavailable rather than claiming a future API.

## Install

- Prefer `mix igniter.install nb_inertia` with the target release's documented source. Use `--typescript`, `--client-framework react|vue`, `--camelize-props`, `--history-encrypt`, `--ssr`, `--with-flop`, `--table`, `--full`, and `--yes` only when the selected task schema exposes them; framework support is version-dependent.
- For `--full`, inspect the effective options and composed installers first. It may install/configure Vite, routes, serializer, TypeScript, Flop, React, and SSR together. For standalone installs, verify the app has the required Phoenix/Inertia runtime pieces and let optional companions remain optional.
- Review changes to web helpers, browser pipeline, root layout, Vite/esbuild config, client dependencies, sample pages, modal assets, and TypeScript output before accepting them.

## Implement and configure

- In controllers use the target version's `NbInertia.Controller` DSL and rendering API. The current source documents `inertia_page`, typed `prop` helpers such as `list_of`, `enum`, `ref`, `shape`, `union`, `nullable`, `optional`, and `render_inertia_page`; use `render_inertia` only according to the compatibility behavior in that version.
- Keep shared props centralized with `NbInertia.SharedProps`/`include_shared_props` where available. Understand initial-load semantics before marking props `partial`, `defer`, `lazy`, or `once`; configure `:nb_inertia` (not the underlying `:inertia` namespace) for endpoint, camelization, history, versioning, and SSR settings.
- For serializers, call the integration functions exposed by the installed release and avoid assuming `nb_serializer` is loaded. For routes, use official Inertia support plus the target `nb_routes` output rather than adding ad-hoc wrappers.
- For modal/slideover flows, ensure every modal has a valid base URL and use the target backend renderer/DSL and matching frontend exports. For SSR or Channels/real-time support, inspect generated assets and runtime supervision/configuration before wiring production code.

## Upgrade or migrate

- Compare locked package versions, CHANGELOG/release notes, generated `lib/inertia.*` and modal files, Inertia client versions, Vite config, and `config/:nb_inertia` before changing a release. Generated files can encode the client framework and SSR contract.
- Migrate one concern at a time: page DSL/rendering, shared-prop semantics, route/form integration, client package exports, modal protocol, or SSR. Preserve optional dependency boundaries and app-owned controller/layout code.
- Re-run type generation after prop/serializer changes and test both initial and partial/deferred visits. When SSR behavior changes, test dev-server warm-up/fallback and production worker/rendering separately.

## Diagnose and verify

- For missing/extra props, inspect page declarations, literal render validation, shared-prop collisions, `partial`/`defer` semantics, and whether validation is disabled in production. For serialization errors, confirm the optional serializer module and runtime opts are available.
- For blank pages or client errors, check inferred component names, generated frontend imports, package-manager lock resolution, root layout helpers, browser pipeline, and Vite/esbuild entry paths. For SSR, inspect worker availability, dev-server URL/health, script path, and `raise_on_failure` behavior.
- Verify with `mix deps.get`, `mix compile`, relevant `mix test`, Inertia request/assertion helpers, generated TypeScript validation when enabled, frontend build, and modal/real-time/SSR smoke tests only when those features are detected and configured.
- If “latest” is requested, consult current package source/HexDocs, official Inertia and Phoenix documentation, and the selected client package release notes; state the check date and reconcile with `mix.lock`/npm lockfiles.
