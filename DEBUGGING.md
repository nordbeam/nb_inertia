# Debugging Guide

Common issues and solutions when working with NbInertia.

## Table of Contents

- [Compile-Time Errors](#compile-time-errors)
- [Runtime Errors](#runtime-errors)
- [Props Issues](#props-issues)
- [Shared Props Issues](#shared-props-issues)
- [TypeScript Issues](#typescript-issues)
- [SSR Issues](#ssr-issues)
- [Performance Issues](#performance-issues)
- [Testing Issues](#testing-issues)

---

## Compile-Time Errors

### Error: "Missing required props for Inertia page"

**Full error:**
```
** (CompileError) Missing required props for Inertia page :users_index

Missing props: :users, :total_count

Add the missing props to your render_inertia call or mark them as optional.
```

**Cause:** You declared props in `inertia_page` but didn't provide them in `render_inertia`.

**Solution 1:** Add the missing props

```elixir
render_inertia(conn, :users_index,
  users: users,
  total_count: length(users)  # Was missing
)
```

**Solution 2:** Mark props as optional if they're not always needed

```elixir
inertia_page :users_index do
  prop :users, :list
  prop :total_count, :integer, optional: true  # Now optional
end
```

**Solution 3:** Use lazy/defer for props loaded on-demand

```elixir
inertia_page :users_index do
  prop :users, :list
  prop :analytics, :map, lazy: true  # Can be omitted
end
```

---

### Error: "Undeclared props provided for Inertia page"

**Full error:**
```
** (CompileError) Undeclared props provided for Inertia page :users_index

Undeclared props: :extra_data, :debug_info

Remove these props or declare them in your inertia_page block.
```

**Cause:** You're passing props that weren't declared in `inertia_page`.

**Solution 1:** Remove the undeclared props

```elixir
render_inertia(conn, :users_index,
  users: users
  # Remove: extra_data: data, debug_info: info
)
```

**Solution 2:** Declare the props

```elixir
inertia_page :users_index do
  prop :users, :list
  prop :extra_data, :map, optional: true  # Now declared
  prop :debug_info, :map, optional: true  # Now declared
end
```

**Pro tip:** In development, this catches typos early!

---

### Error: "Prop name collision detected"

**Full error:**
```
** (CompileError) Prop name collision detected in MyAppWeb.UserController.index

The following props are defined both as shared props and page props: :user

Shared props and page props must have unique names to avoid conflicts.
```

**Cause:** You're using the same prop name in both shared props and page props.

**Solution:** Namespace your props differently

**Before (collision):**
```elixir
# Shared props
inertia_shared do
  prop :user, :map  # Collision!
  prop :flash, :map
end

# Page props
inertia_page :show do
  prop :user, UserSerializer  # Collision!
end
```

**After (no collision):**
```elixir
# Shared props (more specific names)
inertia_shared do
  prop :current_user, :map  # Clear it's the logged-in user
  prop :flash, :map
end

# Page props
inertia_page :show do
  prop :user, UserSerializer  # The user being displayed
end
```

**Naming conventions:**
- Shared props: `current_user`, `auth_user`, `global_flash`, `app_version`
- Page props: `user`, `users`, `post`, `comments`

---

### Error: "Inertia page not declared"

**Full error:**
```
** (ArgumentError) Inertia page not declared: :users_show

Available pages: :users_index, :users_new

To fix this, declare the page in your controller:
    inertia_page :users_show do
      prop :user, UserSerializer
    end
```

**Cause:** You're trying to render a page that wasn't declared with `inertia_page`.

**Solution 1:** Add the page declaration

```elixir
inertia_page :users_show do
  prop :user, UserSerializer
end

def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)
  render_inertia(conn, :users_show, user: {UserSerializer, user})
end
```

**Solution 2:** Use a string component name (skips validation)

```elixir
def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  conn
  |> assign_prop(:user, user)
  |> render_inertia("Users/Show")  # String component name
end
```

---

## Runtime Errors

### Error: "Guard function not found"

**Full error:**
```
** (ArgumentError) Guard function :admin?/1 not found in MyAppWeb.DashboardController

When using `when:` option with inertia_shared, you must define the guard function:

    defp admin?(conn) do
      # Return true or false
    end
```

**Cause:** You used `when: :admin?` but didn't define the function.

**Solution:** Define the guard function

```elixir
defmodule MyAppWeb.DashboardController do
  use MyAppWeb, :controller

  inertia_shared(MyAppWeb.InertiaShared.Admin, when: :admin?)

  # Add the guard function
  defp admin?(conn) do
    case conn.assigns[:current_user] do
      %{role: :admin} -> true
      _ -> false
    end
  end
end
```

**Pro tip:** Guard functions must:
- Accept `conn` as first argument
- Return `true` or `false`
- Be defined as `defp` (private)

---

### Error: Frontend expects camelCase but receives snake_case

**Symptoms:**
```javascript
// Frontend expects
props.totalCount  // undefined

// But backend sends
props.total_count  // works
```

**Cause:** Props camelization is disabled or not working.

**Solution:** Enable camelization in config

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,
  camelize_props: true  # Make sure this is true (default)
```

**Verification:**
```elixir
# In your test
test "props are camelized" do
  conn = inertia_get(conn, ~p"/dashboard")

  # Access with camelCase
  assert_inertia_prop(conn, :totalCount, 42)
end
```

---

## Props Issues

### Issue: Nil props causing frontend errors

**Symptom:**
```javascript
// Frontend crashes
<div>{user.name}</div>  // Cannot read property 'name' of null
```

**Cause:** Passing `nil` for a required prop.

**Solution 1:** Handle nil in backend

```elixir
inertia_page :show do
  prop :user, UserSerializer, optional: true  # Allow nil
end

def show(conn, %{"id" => id}) do
  user = Accounts.get_user(id)  # Returns nil if not found

  case user do
    nil ->
      conn
      |> put_flash(:error, "User not found")
      |> redirect(to: ~p"/users")

    user ->
      render_inertia(conn, :show, user: {UserSerializer, user})
  end
end
```

**Solution 2:** Provide defaults

```elixir
def show(conn, %{"id" => id}) do
  user = Accounts.get_user(id) || %User{}
  render_inertia(conn, :show, user: {UserSerializer, user})
end
```

**Solution 3:** Handle in frontend

```typescript
export default function Show({ user }: ShowProps) {
  if (!user) {
    return <div>User not found</div>
  }

  return <div>{user.name}</div>
}
```

---

### Issue: Large props causing slow responses

**Symptom:** Responses are slow, network tab shows large JSON payloads.

**Diagnosis:**
```elixir
# Check response size in test
test "response size" do
  conn = inertia_get(conn, ~p"/dashboard")
  json = conn.resp_body |> Jason.decode!()
  size = byte_size(conn.resp_body)

  IO.puts("Response size: #{size} bytes")  # If > 100KB, investigate
end
```

**Solution 1:** Use lazy props for expensive data

```elixir
inertia_page :dashboard do
  prop :user, UserSerializer
  prop :analytics, :map, lazy: true  # Only loaded when requested
  prop :reports, :list, lazy: true   # Only loaded when requested
end
```

**Solution 2:** Paginate large lists

```elixir
def index(conn, params) do
  page = Accounts.paginate_users(params)

  render_inertia(conn, :index,
    users: {UserSerializer, page.entries},
    page_number: page.page_number,
    total_pages: page.total_pages
  )
end
```

**Solution 3:** Reduce serializer fields

```elixir
defmodule UserListSerializer do
  use NbSerializer.Serializer

  # Only include fields needed for the list view
  field :id, :integer
  field :name, :string
  field :email, :string
  # Don't include: bio, preferences, settings, etc.
end
```

---

## Shared Props Issues

### Issue: Shared props not appearing in response

**Diagnosis:**
```elixir
test "shared props are present" do
  conn = inertia_get(conn, ~p"/dashboard")

  # Debug: print all props
  props = get_inertia_props(conn)
  IO.inspect(props, label: "All props")

  assert_shared_prop(conn, :app_version)  # Fails
end
```

**Cause 1:** SharedProps module not registered

**Solution:**
```elixir
# In controller
defmodule MyAppWeb.DashboardController do
  use MyAppWeb, :controller

  # Make sure you have this line
  inertia_shared(MyAppWeb.InertiaShared.Base)
end

# Or in web.ex for all controllers
def controller do
  quote do
    use Phoenix.Controller
    use NbInertia.Controller
    inertia_shared(MyAppWeb.InertiaShared.Base)  # Auto-register
  end
end
```

**Cause 2:** Conditional shared props not matching

**Solution:** Check your guard function

```elixir
# If using when: :condition?
inertia_shared(MyAppWeb.InertiaShared.Admin, when: :admin?)

defp admin?(conn) do
  IO.inspect(conn.assigns[:current_user], label: "Current user")  # Debug
  conn.assigns[:current_user]?.role == :admin
end
```

**Cause 3:** Only/except filtering out the action

**Solution:**
```elixir
# If using only:
inertia_shared(MyAppWeb.InertiaShared.Data, only: [:index, :show])

# Make sure current action is in the list
def index(conn, _params) do
  action = Phoenix.Controller.action_name(conn)
  IO.inspect(action, label: "Current action")  # Should be :index
end
```

---

### Issue: Shared props overriding page props

**Symptom:**
```elixir
# Page prop is being ignored
render_inertia(conn, :show, user: specific_user)

# But frontend receives the current_user from shared props instead
```

**Cause:** Prop name collision (page props override shared props, so this shouldn't happen unless there's a bug).

**Solution:** Use different prop names

```elixir
# Shared props
inertia_shared do
  prop :current_user, UserSerializer  # The logged-in user
end

# Page props
inertia_page :show do
  prop :user, UserSerializer  # The user being viewed
end
```

---

## TypeScript Issues

### Issue: Types not generating

**Diagnosis:**
```bash
ls assets/js/types/  # Empty or missing
```

**Cause 1:** nb_ts not installed

**Solution:**
```bash
mix deps.get nb_ts
mix nb_ts.gen.types
```

**Cause 2:** Output directory not configured

**Solution:**
```elixir
# config/config.exs
config :nb_ts,
  output_dir: "assets/js/types"
```

**Cause 3:** No serializers or pages to generate from

**Solution:** Make sure you have either:
- `inertia_page` declarations with prop types
- NbSerializer serializers

```elixir
# This generates types
inertia_page :users_index do
  prop :users, list: UserSerializer
  prop :total_count, :integer
end
```

---

### Issue: Types are stale/out of sync

**Symptom:** TypeScript shows old prop types after changing backend.

**Solution 1:** Manually regenerate

```bash
mix nb_ts.gen.types
```

**Solution 2:** Add to compile workflow

```bash
# In package.json
{
  "scripts": {
    "dev": "mix phx.server & vite",
    "types": "mix nb_ts.gen.types"
  }
}
```

**Solution 3:** Add pre-commit hook

```bash
# .git/hooks/pre-commit
#!/bin/sh
mix nb_ts.gen.types
git add assets/js/types/
```

**Solution 4:** CI/CD check

```yaml
# .github/workflows/ci.yml
- name: Check TypeScript types are up to date
  run: |
    mix nb_ts.gen.types
    git diff --exit-code assets/js/types/
```

---

## SSR Issues

### Error: SSR bundle not found

**Full error:**
```
SSR script not found at: /path/to/priv/static/ssr.js
```

**Cause:** SSR bundle wasn't built.

**Solution:**
```bash
cd assets
npm run build:ssr  # or: bun run build:ssr
```

**Verify:**
```bash
ls priv/static/ssr.js  # Should exist
```

---

### Error: SSR rendering fails in production

**Symptom:** Pages work in development but SSR fails in production with "Page not found" errors.

**Diagnosis:**
```elixir
# Check SSR config
config :nb_inertia,
  ssr: [
    enabled: true,
    raise_on_failure: true,  # Set to true to see actual error
    script_path: "/path/to/ssr.js"
  ]
```

**Common causes:**

**1. Missing page file:**
```
❌ SSR Page Not Found

Component: Users/Index
Expected file: assets/js/pages/Users/Index.tsx

Available pages (5):
  - Dashboard
  - Users/Show
  ...
```

**Solution:** Create the missing page file or check component name spelling.

**2. Import errors in SSR bundle:**
```bash
# Build SSR bundle and check for errors
npm run build:ssr

# Look for:
# - Missing imports
# - Browser-only APIs (window, document, etc.)
# - Incorrect paths
```

**Solution:** Ensure SSR-compatible code

```typescript
// Bad (breaks SSR)
const width = window.innerWidth

// Good (SSR-safe)
const [width, setWidth] = useState(0)
useEffect(() => {
  setWidth(window.innerWidth)
}, [])
```

---

## Performance Issues

### Issue: Slow compile times

**Symptom:** `mix compile` takes 10+ seconds.

**Cause:** TypeScript type generation running on every compilation.

**Solution 1:** Disable auto-generation in development

```elixir
# config/dev.exs
config :nb_ts,
  auto_generate: false  # Generate manually when needed
```

**Solution 2:** Use faster type generation

```bash
# Generate types only when needed
mix ts.gen
```

---

### Issue: Slow test suite

**Symptom:** Tests run slowly due to compile-time validation.

**Solution:** Validation is already disabled in test environment by default, but verify:

```elixir
# This only runs in dev/test
if Mix.env() in [:dev, :test] do
  # Validation code
end
```

If tests are still slow, profile:

```bash
mix test --trace  # See which tests are slow
```

---

## Testing Issues

### Issue: Test helpers not found

**Error:**
```
** (UndefinedFunctionError) function NbInertia.TestHelpers.inertia_get/2 is undefined
```

**Cause:** Test helpers not imported.

**Solution:**
```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import NbInertia.TestHelpers  # Add this line

      @endpoint MyAppWeb.Endpoint
    end
  end
end
```

---

### Issue: Assertions failing with "Page not found in response"

**Cause:** Not making an Inertia request (missing X-Inertia header).

**Solution:** Use `inertia_get` instead of `get`

```elixir
# Bad - missing Inertia header
conn = get(conn, ~p"/users")
assert_inertia_page(conn, "Users/Index")  # Fails

# Good - includes Inertia header
conn = inertia_get(conn, ~p"/users")
assert_inertia_page(conn, "Users/Index")  # Works
```

---

## Getting More Help

### Debug Mode

Add debug output:

```elixir
def index(conn, params) do
  # Debug props before render
  props = [users: users, total: 42]
  IO.inspect(props, label: "Props")

  # Debug conn assigns
  IO.inspect(conn.assigns, label: "Assigns")

  render_inertia(conn, :index, props)
end
```

### Check Inertia Response Structure

```elixir
test "inspect inertia response" do
  conn = inertia_get(conn, ~p"/users")

  # Decode and inspect full response
  response = conn.resp_body |> Jason.decode!()
  IO.inspect(response, label: "Full Inertia response")

  # Check structure
  assert response["component"]
  assert response["props"]
  assert response["version"]
end
```

### Enable Verbose Logging

```elixir
# config/dev.exs
config :logger, :console,
  level: :debug  # See all debug messages
```

---

## Resources

- **Documentation:** https://hexdocs.pm/nb_inertia
- **Migration Guide:** [MIGRATION.md](MIGRATION.md)
- **Cookbook:** [COOKBOOK.md](COOKBOOK.md)
- **GitHub Issues:** https://github.com/nordbeam/nb_inertia/issues
- **Discussions:** https://github.com/nordbeam/nb_inertia/discussions

If you encounter an issue not covered here, please [open an issue](https://github.com/nordbeam/nb_inertia/issues) with:
- Elixir/Phoenix versions
- nb_inertia version
- Full error message
- Minimal reproduction code
