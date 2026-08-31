# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Full Inertia.js 3.7 protocol and React/Vue adapter compatibility, including
  deferred-prop rescue metadata, nested deferred/once dot paths, server-provided
  head reconciliation, polling state, instant/client visits, cached navigation,
  optimistic router/form chains, and the current official adapter exports.
- `inertia_defer/2` and `inertia_defer/3` support for `on_error: :ignore`, with
  `rescuedProps` output and deferred-rescue telemetry.
- Generated app barrels now expose `useFormWithPrecognition` and
  `useHttpWithPrecognition` in addition to the official Inertia 3.7 surface.
- Repeatable performance tooling with `mix nb_inertia.bench`, the lightweight
  `mix nb_inertia.perf_gate` budget check, and documented smoke budgets in
  `bench/perf_budgets.exs`.
- Publish-ready React, Vue, modal, realtime, and shared TypeScript package
  entrypoints for `@nordbeam/nb-inertia`.
- Comprehensive compile-time validation test suite
  (`test/nb_inertia/compile_time_validation_test.exs`).

### Changed
- Controller-based `inertia_page` declarations plus `render_inertia_page/4`
  are the supported typed page contract path.
- React package entrypoints are built to `dist/react/*`; Vue core entrypoints
  ship as bundler-consumed TypeScript source, with `./vue/modals` using a
  JavaScript runtime stub and a separate `index.d.ts` type surface.

### Removed
- Removed the legacy `NbInertia.Page` and `NbInertia.PageController` public APIs,
  including `mount/2`, `action/3`, colocated Page `render/0` callbacks,
  `mix nb_inertia.install --pages`, and `mix nb_inertia.migrate_to_pages`.

### Fixed
- React router and form wrappers preserve native Inertia class prototypes,
  getters, fluent builders, modal request headers, and separate submit routes.
- React and Vue modal pages retain the full Inertia 3.7 page metadata, and modal
  links follow native target, modifier-key, and non-left-click behavior.
- Inertia response handling now preserves redirect flags, avoids fragment
  redirects during prefetches, handles external hash locations correctly,
  emits `Vary: X-Inertia`, and redirects empty successful responses.
- Modal base-page composition now dispatches internally through the Phoenix
  endpoint instead of depending on Req.
- Modal rendering preserves string-component props, query strings, styling
  configuration, and nil modal options.
- Core adapter handling for struct serialization, explicit `ssr: false`, and
  3xx redirects without `Location` headers is hardened.
- `inertia_shared do ... end` macro now correctly registers inline shared props
  (was silently discarding them due to macro clause ordering)
- Props with `from: :assigns` are no longer incorrectly flagged as "missing required props"
  in compile-time validation
- Prop collision detection between shared props and page props now works correctly
