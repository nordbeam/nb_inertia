---
name: nb-inertia
description: 'Implement, configure, upgrade, diagnose, and verify nb_inertia Phoenix integrations with typed pages, shared props, SSR, modals, and real-time features.'
---

# NbInertia

Use this skill for `nb_inertia` controller/page contracts, Inertia rendering,
shared or lazy props, SSR, modal/slideover flows, real-time updates, frontend
adapters, and optional companion-package integrations.

## Route to the right guidance

- For a copyable NbSerializer-backed typed page, read
  [references/typed-serializer-page.md](references/typed-serializer-page.md).
  It covers the serializer, `inertia_page` contract, explicit
  `{Serializer, value}` rendering, generated artifacts, React, and controller
  tests.
- Any task that generates or validates TypeScript, Zod, PageProps, or `~TS`
  output MUST also load the `nb-ts` skill. It owns generator flags, tsgo
  setup, output inspection, and validation recovery; this skill only describes
  the Inertia integration point.
- For serializer DSL or serialization behavior, also load `nb-serializer`.
  For generated route helpers, also load `nb-routes` (and `nb-vite` when its
  watcher/build integration is in scope).

## Discover the target release

- Inspect `mix.exs`, `mix.lock`, `assets/package.json` and lockfile, Phoenix
  web helpers/router, Vite/esbuild configuration, `config/config.exs`,
  `config/runtime.exs`, and generated frontend entrypoints before choosing an
  API. Read the selected README, installer, and relevant source after the
  installed versions and optional dependencies are known.
- Treat `nb_serializer`, `nb_ts`, `nb_routes`, `nb_flop`, DenoRider, and client
  packages as optional unless the target release makes them required. Preserve
  app-owned `file:`, workspace, or Git sources.
- Detect installer flags, modules, exports, and generated files in the locked
  release; do not claim a feature that is absent from that release.

## Implement

- Declare pages with `NbInertia.Controller` and `inertia_page`; prefer the
  native `prop`, `list_of`, `ref`, `enum`, `shape`, `union`, `nullable`, and
  `optional` helpers. Prefer `render_inertia_page` for explicit page props and
  validation; use pipe-friendly `render_inertia` only for its compatibility
  behavior.
- Keep shared props centralized with `NbInertia.SharedProps`/
  `include_shared_props`. Configure `:nb_inertia`, not the underlying
  `:inertia` namespace. Preserve optional-prop initial-load semantics for
  partial, deferred, lazy, once, and default-backed props.
- Preserve the official Inertia adapter contract: resolver functions receive
  both `name` and `page`, and page responses retain nested partial/deferred
  metadata. Modal renderers need a valid base URL and explicitly owned fallback
  head nodes; SSR must use the same provider tree and server-head behavior as
  the browser entrypoint.
- Use official Inertia navigation/components and the generated app glue. Do
  not narrow native types or add ad-hoc route wrappers around `nb_routes`.

## Verify and recover

- Run `mix deps.get`, `mix compile`, focused controller/serializer tests,
  generated-type validation through the `nb-ts` skill, and the app's strict
  TypeScript/Vite+ checks. Test initial and partial/deferred visits when those
  options are present; add modal, real-time, or SSR smoke coverage only when
  configured.
- Use the exact npm 12/Vite+ commands and recovery notes in the typed-page
  reference. Do not hand-edit generated TypeScript or suppress a failed
  serializer/type contract to make a check pass.
- For missing props, inspect the page declaration, literal render validation,
  shared-prop collisions, and partial/deferred semantics. For blank pages,
  inspect component naming, generated imports, package resolution, entry paths,
  and SSR worker/dev-server health.
