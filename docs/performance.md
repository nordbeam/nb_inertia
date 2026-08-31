# Performance Benchmarks

This repository includes a repeatable benchmark suite for nb_inertia server-side
hot paths and a lightweight performance gate for CI/local smoke checks.

## Commands

Run the smoke gate:

```bash
mix nb_inertia.perf_gate
# Run only the smallest fixture when iterating locally.
mix nb_inertia.perf_gate --sizes small
```

Run the full benchmark suite:

```bash
mix nb_inertia.bench
```

Limit by size or scenario:

```bash
mix nb_inertia.bench --sizes small,medium
mix nb_inertia.bench --scenarios controller_rendering,prop_serializer_recursion
mix nb_inertia.bench --iterations 100 --samples 10
```

## Covered Paths

The suite runs small, medium, and large fixtures through these scenarios:

- `controller_rendering`: `NbInertia.Controller` page rendering with DSL props,
  shared props, defaults, once/defer/lazy modifiers, and JSON response encoding.
- `core_controller_rendering`: direct `NbInertia.CoreController.render_inertia/3`
  with merge, deep merge, prepend, scroll, optional, and once props.
- `prop_runtime_processing`: `NbInertia.PropRuntime` default/from filling and DSL
  prop assignment.
- `prop_serializer_recursion`: `NbInertia.PropSerializer` recursive map/list/struct
  traversal.
- `shared_prop_resolution`: shared prop modules, conditional shared modules, and
  inline shared defaults.
- `camelization`: nested snake_case to camelCase prop transformation through
  CoreController rendering.
- `flash_plug_overhead`: `NbInertia.Plug` request setup plus Inertia/Phoenix flash
  merge and camelization.
- `modal_composition`: modal struct/config composition and modal prop preparation.
- `ssr_call_preparation`: SSR page payload construction/encoding without requiring
  DenoRider or an external SSR server.

## Reading Output

`avg_us`, `p50_us`, and `p95_us` are microseconds per operation. `reductions/op`
is BEAM scheduler reductions per operation. `mem_delta_b` and `bin_delta_b` are
process and binary memory deltas across the measured samples. `gc_words/op`
reports garbage-collector reclaimed words per operation.

Memory deltas are practical smoke indicators, not exact allocation counts. Use
the full benchmark for before/after comparisons on the same machine, with the
same Elixir/OTP versions and comparable system load.

## Budgets

Smoke budgets live in `bench/perf_budgets.exs`. The gate uses all three fixture
sizes with 40 operations across 8 samples per scenario/size.
That keeps the default check short while ensuring that scaling regressions in the
medium and large fixtures are covered in CI. Use `--sizes small` for a faster
local check.

The p95 limits are per-operation microseconds. They are rounded up from repeated
gate-shaped runs and leave roughly 3–10× headroom for scheduler and runner
variance (with a larger floor for very small operations). The largest measured
paths remain below 20 ms/op, so the largest ceiling is still tighter than the
previous 75–150 ms thresholds. Memory limits remain separate smoke indicators;
they are not allocation-count measurements.

When updating a budget:

1. Run `mix nb_inertia.bench` before and after the change.
2. Confirm the new numbers are expected and repeatable.
3. Update `bench/perf_budgets.exs` in the same commit as the performance change.
4. Note the reason for the budget change in the pull request.
