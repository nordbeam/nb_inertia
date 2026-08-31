# Page-schema runtime

`nb_ts` can emit a page-schema registry alongside its TypeScript declarations.
`nb_inertia` consumes that registry at the Inertia lifecycle boundary, before a
resolved page is committed to browser history or rendered by React/Vue.

## Registry contract

The runtime intentionally depends on one small interface. A generated registry
only needs a component-name lookup:

```ts
import type { PageSchema, PageSchemaRegistry } from '@nordbeam/nb-inertia/shared/schemaRuntime';

const pages: Record<string, PageSchema> = {
  'Users/Index': {
    fields: {
      users: {
        parse(value) {
          if (!Array.isArray(value)) throw new Error('users must be an array');
          return value;
        },
      },
    },
  },
};

export const pageSchemas: PageSchemaRegistry = {
  get(component) {
    return pages[component];
  },
};
```

Entries may use `safeParse`, `parse`, `decode`, `validate`, or `transform`.
Generated registries should prefer `safeParse` or `parse`. The generated
`nb_ts` Zod output is directly consumable:

```ts
export const pageSchemas: Record<string, PageSchema> = { /* ... */ };
export const pageSchemaRegistry: PageSchemaRegistry = {
  get(component) { return pageSchemas[component]; },
};
```

`get(component)` is the supported registry contract. A registry-level
`transforms` flag means transformed entries may exist; it is not a blanket
decode marker. Generated codecs should mark the individual entry/field with
`transforms: true`, `decodeEnabled: true`, or `isTransform: true` (a wrapper of
the form `{ schema, transforms: true }` is also supported). The runtime also
recognizes Zod 4 codec/pipe/transform metadata, so generated ISO-date codecs
are classified as `decode` failures while normal Zod object/type failures are
classified as `validation`. A failed decoder is never replaced with its wire
input.

The current generated entry shape is:

```ts
{
  schema,
  fullSchema,
  wireSchema,
  fields,
  shape,
  propertySchemas,
  required,
  transformFields,
}
```

`fields` (and its aliases) are the lifecycle boundary for every generated page
entry. Complete phases enforce the entry's `required` list; partial/deferred
payloads validate/decode only fields present in the response. `fullSchema` and
`wireSchema` remain available to explicit whole-page helpers such as
`decodePageProps` and are not implicitly run by the lifecycle runtime. This is
important when one page contains both ordinary validation fields and decoded
fields: a failure in one ordinary field remains `validation`, not `decode`.
`transformFields` documents which fields are wrapped with transform metadata,
while ordinary fields remain plain Zod schemas.

To preserve structural sharing for partial reloads, a page entry can expose a
`fields` map; `props`, `shape`, `propertySchemas`, and JSON-schema `properties`
are accepted aliases. Fields absent from a partial or deferred response are
not parsed or replaced. Complete phases (initial/navigation/instant/history,
SSR, modal, and prefetch) process the generated fields and enforce required
fields; partial and deferred phases process only fields present in the
response.

## React and Vue setup

The installer-generated `@/lib/inertia` barrel exports the schema-aware
`createInertiaApp`. Pass the generated registry as an app option:

```ts
import { createInertiaApp } from '@/lib/inertia';
import { pageSchemaRegistry } from '@/types/pages';

createInertiaApp({
  pageSchemas: pageSchemaRegistry,
  resolve: (name) => pages[`./pages/${name}.tsx`](),
  setup({ App, el, props }) {
    createRoot(el).render(<App {...props} />);
  },
});
```

Vue uses the same option and registry shape. The option is removed before the
official Inertia adapter receives it. For an application that centralizes
configuration, call `configurePageSchemaRuntime({ registry: pageSchemas })`
before `createInertiaApp` instead.

The runtime is also available without a framework adapter through
`createPageSchemaRuntime` and `installPageSchemaRuntime` from
`@nordbeam/nb-inertia/shared/schemaRuntime`.

## Policies and failures

`mode` controls failures:

- `throw` (the default outside production) raises `PageSchemaRuntimeError` and
  is friendly to Vite's development error overlay.
- `report` calls `onFailure` (or `reporter`) and omits the invalid prop. An
  optional `overlay` callback can integrate with a custom development overlay.
- `off` bypasses registry lookup and parsing entirely.

Production defaults to `off`; choose `report` or `throw` explicitly when
production enforcement is desired:

```ts
createInertiaApp({
  pageSchemas,
  schemaRuntime: {
    mode: import.meta.env.DEV ? 'throw' : 'report',
    onFailure(failure) {
      sendToTelemetry(failure);
    },
  },
  // ...normal Inertia options
});
```

Failures are categorized as `validation` or `decode`. A decoder/transform
failure never falls back to the original wire value: report mode removes that
value and throw mode prevents the page from being committed. This distinction
is useful when deciding whether a backend contract is wrong (`validation`) or
the client decoder/transform is broken (`decode`).

## Lifecycle coverage

The adapter processes initial DOM/SSR props and pages passed directly to
`createInertiaApp`, regular navigation, partial reloads, deferred props,
instant/client-side visits, history/back-forward restoration, and nested
`_nb_modal` payload props. Prefetched JSON is decoded before the modal prefetch
cache receives it. The shared runtime performs no browser access while running
in SSR, and the disabled path does no registry lookup or parsing.

## Page-scoped props hooks

Bind the generated `Pages` map once in application glue; the hook reads the
official Inertia `usePage()` accessor and returns the props already processed
by the central runtime:

```tsx
import type { Pages } from '@/types/pages';
import { createUsePageProps } from '@nordbeam/nb-inertia/react/usePageProps';

export const usePageProps = createUsePageProps<Pages>();
// usePageProps('Users/Index') -> Pages['Users/Index']
```

Vue uses the same factory from `@nordbeam/nb-inertia/vue/usePageProps`. In
development, a component mismatch raises `PagePropsComponentMismatchError`;
production returns the current page's already-decoded props. The hook never
re-parses a page.

## Production bundle behavior

The framework `createInertiaApp` adapters import the schema runtime dynamically
only when a registry is supplied. When `--zod` is selected, the TypeScript
installer template additionally loads `@/types/pages` only inside an
`import.meta.env.DEV` branch. Vite/Rolldown folds that branch out of production
output, leaving the default production bundle free of the generated registry
and Zod. Pass `pageSchemas` and an explicit `schemaRuntime` policy (for example
`{ mode: 'report', onFailure }`) to opt production checks back in.
