# NbSerializer-backed typed Inertia page

Use this reference when an app needs one read-only page that proves the full
backend-to-frontend contract. Replace the application-specific module names
and data lookup with the target app's existing Ecto schema/context.

## 1. Serializer and typed page contract

Define a dedicated serializer with explicit scalar fields and a computed field.
The serializer metadata, not a generic `:map`, is the page prop's type source.

```elixir
defmodule MyAppWeb.Serializers.ContactProfileSerializer do
  use NbSerializer.Serializer

  schema do
    field :id, :number
    field :first_name, :string
    field :last_name, :string
    field :display_name, :string, compute: :display_name
  end

  def display_name(%{first_name: first_name, last_name: last_name}, _opts) do
    Enum.join([first_name, last_name], " ")
  end
end
```

Declare the page prop with `ref/1`, keeping the serializer visible in the
contract:

```elixir
defmodule MyAppWeb.ContactController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  alias MyAppWeb.Serializers.ContactProfileSerializer

  inertia_page :contacts_show do
    prop :contact, ref(ContactProfileSerializer)
  end

  def show(conn, %{"id" => id}) do
    contact = MyApp.Contacts.get_contact!(id)

    render_inertia_page(conn, :contacts_show,
      contact: {ContactProfileSerializer, contact}
    )
  end
end
```

The `{Serializer, value}` tuple is intentional: `render_inertia_page/4`
materializes it through the normal NbInertia prop pipeline, while the page DSL
and NbTs can still discover the serializer type. A `{Serializer, value, opts}`
tuple is available when serializer runtime options are needed.

Add the route using the app's existing router scope:

```elixir
scope "/", MyAppWeb do
  get "/contacts/:id", ContactController, :show
end
```

## 2. Generate TypeScript, Zod, and PageProps

Generation/validation is an `nb-ts` task. Load the `nb-ts` skill before doing
this section and follow the installed task's supported flags.

Configure Zod emission (or use the equivalent installer/task option exposed by
the target release):

```elixir
config :nb_ts,
  output_dir: "assets/js/types",
  emit: [:interfaces, :zod]
```

From the application root, compile first, then generate and validate:

```bash
mix compile
mix nb_ts.gen --zod
mix nb_ts.gen --validate
```

Depending on the configured release, `mix nb_ts.gen` after the `emit` config
is equivalent to the `--zod` invocation, and `mix ts.gen` may be an alias.
Inspect the generated files; do not hand-edit them. A successful page discovery
should include equivalents of:

- `assets/js/types/ContactProfileSerializer.ts` with serializer interface and
  Zod schema/runtime exports;
- `assets/js/types/ContactsShowProps.ts` (or the release's page-prop filename);
- `assets/js/types/pages.ts` with `Pages`, `pageSchemas`, and
  `pageSchemaRegistry`; and
- the generated barrel/index exports.

If validation says the `tsgo` binary is missing, run the recovery task from the
`nb-ts` skill and retry:

```bash
mix nb_ts.download_tsgo
```

On macOS ARM when platform detection needs an explicit value:

```bash
TSGO_PLATFORMS=darwin-arm64 mix nb_ts.download_tsgo
```

Fix the first reported source-contract error rather than changing generated
files or ignoring validation failures.

## 3. React page with zero handwritten prop annotations

With the TypeScript + Zod installer, `assets/js/lib/inertia.ts` should bind the
generated `Pages` map once:

```ts
import { createUsePageProps as createTypedUsePageProps } from '@nordbeam/nb-inertia/react/usePageProps';
import type { Pages } from '@/types/pages';

export const usePageProps = createTypedUsePageProps<Pages>();
```

The page consumes the generated runtime value; it does not declare an
interface, generic, or cast for its props:

```tsx
import { Head, usePageProps } from '@/lib/inertia';

export default function ContactsShow() {
  const { contact } = usePageProps('Contacts/Show');

  return (
    <>
      <Head title={contact.displayName} />
      <main>
        <h1>{contact.displayName}</h1>
        <p>Contact #{contact.id}</p>
      </main>
    </>
  );
}
```

If the installer did not create this map-bound export, add the small app-owned
glue above rather than annotating each page. The generated `Pages` map remains
the source of truth.

## 4. Controller tests and assertion semantics

Use an Inertia request in a Phoenix `ConnCase`; a plain `get` does not exercise
the Inertia response path:

```elixir
test "renders a serialized contact", %{conn: conn} do
  contact = insert(:contact, first_name: "Ada", last_name: "Lovelace")
  conn = inertia_get(conn, ~p"/contacts/#{contact.id}")

  assert_inertia_page(conn, "Contacts/Show")
  assert_inertia_props(conn, [:contact])
  assert_inertia_prop(conn, "contact.id", contact.id)
  assert_inertia_prop(conn, "contact.displayName", "Ada Lovelace")
end
```

`assert_inertia_props/2` checks only top-level key presence. A top-level
`assert_inertia_prop(conn, :contact, expected_map)` compares the complete map;
use the string dot-path form for one nested field. Dot paths resolve atom/string
keys and snake_case/camelCase variants, so they work with camelized wire props.
`refute_inertia_prop/2` accepts the same top-level or dot-path lookup.

## 5. npm 12 and Vite+ checks

The first-party package and current generated apps require npm 12.0.2. From
the JavaScript/assets directory, use Corepack's pinned npm and the Vite+ binary:

```bash
corepack npm@12.0.2 install
corepack npm@12.0.2 run typecheck
corepack npm@12.0.2 run check
corepack npm@12.0.2 exec -- vp fmt --check
corepack npm@12.0.2 exec -- vp build --mode production
```

Use the app's declared script names (for example `types:check`,
`format:check`, `build:ssr`) when they differ; keep the npm prefix pinned:

```bash
corepack npm@12.0.2 run types:check
corepack npm@12.0.2 run format:check
corepack npm@12.0.2 run build:ssr
```

If the host npm is rejected by `devEngines`, prefix every npm command with
`corepack npm@12.0.2`; do not bypass the version check. If `vp` is not found,
install dependencies with that same command and invoke it through
`corepack npm@12.0.2 exec -- vp ...`. A missing `vite` executable is not fixed
by switching package managers: Vite+ projects intentionally expose `vp`.
