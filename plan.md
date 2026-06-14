# nb_inertia DSL evolution plan

## North star

Treat `nb_inertia` as a typed page-contract system for Phoenix, not just a nicer `render_inertia` wrapper.

The DSL is already strongest when it:

- makes page inputs and outputs explicit
- keeps protocol behavior close to the page contract
- gives compile-time feedback before runtime mistakes happen

This plan focuses on preserving those strengths while reducing duplication and “magic”.

## Research summary

The current DSL is split across several cooperating layers:

- `lib/nb_inertia/controller.ex` defines the controller-side contract DSL (`inertia_page`, `prop`, `render_inertia`, shared prop handling, serializer integration, runtime prop wrapping).
- `lib/nb_inertia/core_controller.ex` owns the protocol-level prop primitives (`inertia_optional`, `inertia_merge`, `inertia_prepend`, `inertia_match_merge`, `inertia_scroll`, `inertia_defer`, `inertia_once`) and page object assembly.
- `lib/nb_inertia/shared_props.ex` defines reusable shared-prop modules with validation.
- `lib/nb_inertia/validation.ex` and the Credo checks under `lib/nb_inertia/credo/check/**` provide additional static and runtime safeguards.

## What is already working well

1. **Explicit page contracts**
   - `inertia_page` and `prop` make page shape visible in one place.

2. **Strong compile-time direction**
   - controller macros validate missing and extra props during macro expansion in dev/test
   - Credo checks reinforce the intended architecture before compile

3. **Good adapter-level protocol coverage**
   - `core_controller.ex` already models merge, prepend, match, scroll, once, deferred props, shared prop metadata, and related response fields
   - `scroll_metadata.ex` shows the adapter is absorbing backend paginator differences instead of leaking them to app code

4. **Useful architecture nudges**
   - `prop_from_assigns` encourages declarative data flow
   - `declare_inertia_page`, `missing_inertia_page_props`, and `modal_requires_base_url` all push users toward the happy path

## Main problems to solve

### 1. The DSL has two semantic layers that do not line up cleanly

Some behavior is declaration-first:

- `prop ..., partial: true`
- `prop ..., defer: true`
- `prop ..., once: true`
- `prop ..., from: :assigns`

Other behavior is helper-first:

- `inertia_prepend/1`
- `inertia_match_merge/2`
- `inertia_scroll/2`

This makes the API feel uneven. The user has to know which behaviors belong in the `prop` declaration and which only exist as runtime wrappers.

### 2. The same prop-processing rules are implemented in multiple places

The controller render paths all apply:

- shared props
- `from:`/`default:`
- serializer tuple handling
- DSL option wrapping
- shared prop metadata

The duplication is most visible inside the controller rendering and prop-resolution paths. The behavior is similar enough that it should come from one internal pipeline.

### 3. Shared props are conceptually inconsistent

`SharedProps` modules are real runtime providers, while inline controller shared declarations need clear runtime behavior and documentation.

That is a surprising semantic split for two features with the same name.

### 4. Validation is strong but fragmented

There are currently multiple validation systems:

- compile-time macro validation in `controller.ex`
- compile-time checks in controller macros
- runtime validation helpers in `validation.ex`
- Credo checks for design/readability/warnings

This is valuable, but the rules are distributed and partially overlapping. Some gaps still remain, such as shared-module collision validation and option-combination consistency.

### 5. Modal and advanced protocol behavior are powerful but spread out

Modal behavior is split across:

- controller macros
- controller page declarations
- controller rendering helpers
- modal renderer infrastructure

Likewise, advanced prop behavior is split between prop declarations and protocol helpers. The end result is powerful, but the mental model is expensive.

## Plan

## Phase 1 — define the DSL model explicitly

Create a single internal model for three categories:

1. **page contract**
   - prop names
   - types/serializers
   - defaults
   - source (`from:`)

2. **response behavior**
   - partial/defer/once/lazy
   - merge/prepend/match/scroll

3. **transport metadata**
   - shared props
   - modal config
   - channel config
   - history/fragment/camelization options

Outcome:

- a clearer ownership boundary inside the library
- less ambiguity about whether a feature belongs on `prop`, `shared`, `modal`, or a runtime helper

## Phase 2 — unify prop behavior behind one internal pipeline

Extract a single internal prop-resolution pipeline used by controller-based pages.

That pipeline should own:

- shared prop resolution
- `from:` and `default:` filling
- serializer tuple resolution
- DSL modifier wrapping
- metadata generation (`sharedProps`, `mergeProps`, `prependProps`, `matchPropsOn`, `scrollProps`, etc.)

Outcome:

- less duplication inside `controller.ex`
- fewer behavior drifts between controller render paths
- simpler future feature work

## Phase 3 — make prop modifiers symmetrical

Move toward a model where the common behaviors can be expressed declaratively on `prop`, while keeping the runtime helpers as escape hatches.

Examples of the direction:

- `merge: true | :deep`
- `prepend: true`
- `match_on: :id`
- `scroll: true | [wrapper: "entries", match_on: :id]`

Keep helpers like `inertia_scroll/2` and `inertia_match_merge/2`, but make them the low-level API rather than the only API for those behaviors.

Outcome:

- the public DSL becomes easier to learn
- advanced behavior reads as part of the page contract instead of scattered response shaping

## Phase 4 — resolve the shared props inconsistency

Choose one of these and commit to it:

### Preferred option

Make inline controller `shared do ... end` declarations a real runtime feature, not just a type declaration.

That means:

- support `from:` and possibly other declarative sources there
- apply those values in the controller render pipeline
- validate collisions the same way as other shared props

### Fallback option

If inline shared props are intentionally type-only, rename or reposition the feature so it does not read like runtime shared props.

Outcome:

- fewer surprises
- easier explanation of the shared props story

## Phase 5 — centralize validation and diagnostics

Create one internal contract/introspection module that becomes the source of truth for:

- controller macro validation
- controller page validation
- runtime validation
- nb_ts/extractor integration
- Credo checks where possible

Then add missing validations for:

- shared module collisions
- conflicting prop modifier combinations
- unsupported modal/channel/shared combinations
- controller render-path parity gaps

Outcome:

- stronger guarantees with less duplicated logic
- better error messages because they come from one place

## Phase 6 — simplify the public surface without losing power

Keep the primary public path small:

- `prop`
- `shared`
- `modal`
- `channel`
- `render_inertia`
- `inertia` / `inertia_resource`

Treat the protocol helpers in `core_controller.ex` as advanced tools and internal building blocks.

This does not mean removing them; it means the main docs, examples, and API shaping should bias toward the contract DSL first and the raw protocol helpers second.

Outcome:

- better readability in app code
- lower onboarding cost
- easier long-term maintenance

## Phase 7 — preserve escape hatches and migrate incrementally

Do not break the current strengths:

- string component names should continue to work
- low-level runtime helpers should continue to exist
- existing controller pages should remain valid

Use additive changes first, then warnings/deprecations, then removal only when the replacement is clearly better.

Outcome:

- safer adoption for existing apps
- room to refine the DSL without forcing a rewrite

## Recommended implementation order

1. extract shared prop + prop resolution internals
2. introduce a single contract/introspection layer
3. make advanced prop behaviors symmetrical on `prop`
4. resolve inline controller shared-prop semantics
5. tighten validations and error messages
6. only then consider public deprecations

## Specific recommendations

1. **Unify controller execution paths**
   - reduce duplicated behavior in `controller.ex`

2. **Make `prop` the canonical place for common behavior**
   - declaration-first for merge/prepend/match/scroll where possible

3. **Keep `core_controller.ex` as the protocol engine**
   - protocol helpers stay, but the DSL should compile down into them

4. **Fix the `shared` naming mismatch**
   - same name should imply the same runtime semantics

5. **Move validations toward one source of truth**
   - one contract representation powering macros, runtime, Credo, and extraction

6. **Keep the DSL opinionated**
   - continue pushing users toward explicit contracts, not ad hoc maps

## Referenced files

- `lib/nb_inertia/controller.ex`
- `lib/nb_inertia/core_controller.ex`
- `lib/nb_inertia/scroll_metadata.ex`
- `lib/nb_inertia/shared_props.ex`
- `lib/nb_inertia/validation.ex`
- `lib/nb_inertia/credo/check/design/declare_inertia_page.ex`
- `lib/nb_inertia/credo/check/readability/prop_from_assigns.ex`
