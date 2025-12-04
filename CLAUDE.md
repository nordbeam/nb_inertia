# CLAUDE.md - nb_inertia

Developer guidance for Claude Code when working with the nb_inertia package.

## Package Overview

**nb_inertia** provides advanced Inertia.js integration for Phoenix with declarative page DSL, type-safe props, and enhanced client-side components that seamlessly integrate with nb_routes.

**Location**: `/Users/assim/Projects/nb/nb_inertia`

## Key Features

- **Declarative Page DSL**: Define Inertia pages with compile-time prop validation
- **Type-Safe Props**: Automatic TypeScript type generation via nb_ts integration
- **useForm with Route Binding**: Enhanced useForm hook that binds to nb_routes RouteResult objects
- **Modal System**: Render Inertia pages as modals/slideovers without full page navigation
- **SSR-Safe Components**: Head and usePage with modal context support
- **Shared Props**: Automatically add props to all Inertia responses
- **SSR Support**: Optional server-side rendering with DenoRider
- **Optional Dependencies**: Works with or without nb_serializer, nb_routes, and nb_ts

## Architecture

### What Official Inertia Already Supports

**IMPORTANT**: Official `@inertiajs/react` and `@inertiajs/vue3` already support `UrlMethodPair` (same as RouteResult) natively:

```typescript
// Official Inertia router and Link already support RouteResult objects!
import { router, Link } from '@inertiajs/react';
import { user_path, update_user_path } from './routes';

router.visit(user_path(1));                // RouteResult works!
router.visit(update_user_path.patch(1));   // Method auto-detected!
<Link href={user_path(1)}>View</Link>      // RouteResult in href works!
```

**No wrappers needed for router and Link** - use official Inertia directly.

### Core Components

1. **NbInertia.Controller** (`lib/nb_inertia/controller.ex`)
   - Declarative `inertia_page` macro for defining pages
   - Prop validation and serialization
   - Integration with nb_serializer and nb_ts

2. **Enhanced Client Components** (`priv/nb_inertia/`)
   - React: `useForm.tsx` (route binding), `Head.tsx` (modal context), `usePage.tsx` (modal context)
   - Vue: `useForm.ts` (route binding)
   - Modal system components in `modals/` subdirectory
   - Shared types in `shared/types.ts`

3. **Installer** (`lib/mix/tasks/nb_inertia.install.ex`)
   - Igniter-based automated setup
   - Configures nb_vite, nb_ts, and esbuild

## Wayfinder-Style Integration

### Concept

Official `@inertiajs/react` and `@inertiajs/vue3` already support `UrlMethodPair` (same as RouteResult from nb_routes). This means you can pass RouteResult objects directly to official Inertia components without any wrappers.

nb_inertia adds one enhancement: **useForm with route binding** - allowing you to bind a form to a route so `submit()` doesn't need method/URL arguments.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Phoenix Backend                          │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Router (Phoenix.Router)                                  │   │
│  │   get "/users/:id", UserController, :show               │   │
│  │   patch "/users/:id", UserController, :update           │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ nb_routes (Route Helper Generator)                       │   │
│  │   Generates: user_path(id) → { url, method }            │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         │ Compile-time                           │
│                         │ Code Generation                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ nb_inertia (Page DSL + Props)                           │   │
│  │   inertia_page :users_show do                           │   │
│  │     prop :user, UserSerializer                          │   │
│  │   end                                                    │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ nb_ts (TypeScript Type Generator)                       │   │
│  │   Generates: UsersShowProps, User types                 │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
                          │ Generated Files
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Frontend (Assets)                           │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ assets/js/routes.js + routes.d.ts (from nb_routes)      │   │
│  │   export const user_path: (id) => RouteResult           │   │
│  │   export const update_user_path: RouteHelper            │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ assets/js/types/index.ts (from nb_ts)                   │   │
│  │   export interface UsersShowProps { user: User }        │   │
│  │   export interface User { id: number; name: string }    │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Use official Inertia + nb_inertia enhancements          │   │
│  │   import { router, Link } from '@inertiajs/react';      │   │
│  │   import { useForm } from '@nordbeam/nb-inertia/react'; │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ React Component (assets/js/pages/Users/Show.tsx)        │   │
│  │                                                          │   │
│  │   import { router, Link } from '@inertiajs/react';      │   │
│  │   import { user_path } from '@/routes';                 │   │
│  │   import type { UsersShowProps } from '@/types';        │   │
│  │                                                          │   │
│  │   export default function Show({ user }: UsersShowProps)│   │
│  │     // RouteResult object works natively in official!   │   │
│  │     router.visit(user_path(user.id));                   │   │
│  │     <Link href={user_path(user.id)}>View</Link>         │   │
│  │   }                                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

Key Integration Points:
1. nb_routes generates RouteResult objects: { url: string, method: HTTPMethod }
2. nb_inertia enhanced components accept RouteResult objects
3. nb_ts generates TypeScript types for props
4. All three packages work together seamlessly via compile-time code generation
```

### Package Responsibilities

#### nb_routes
- **What it does**: Generates JavaScript/TypeScript route helpers from Phoenix routes
- **Output**: `routes.js` + `routes.d.ts` with functions that return RouteResult objects
- **Key type**: `RouteResult = { url: string, method: 'get' | 'post' | ... }`

#### nb_inertia
- **What it does**: Provides enhanced useForm with route binding, SSR-safe components with modal context, and a complete modal system
- **Key components**: `useForm` (route binding), `Head` (modal context), `usePage` (modal context), Modal system
- **Note**: Official `@inertiajs/react` and `@inertiajs/vue3` already support RouteResult natively for `router` and `Link`

#### nb_ts
- **What it does**: Generates TypeScript types for Inertia page props and serializers
- **Output**: `types/index.ts` with prop interfaces
- **Integration**: Works with nb_inertia's page DSL to generate accurate types

### How They Work Together

1. **Backend**: Define routes in Phoenix router
2. **nb_routes**: Generates route helpers that return RouteResult objects
3. **nb_inertia**: Backend DSL defines props, provides useForm with route binding
4. **nb_ts**: Generates TypeScript types for props
5. **Frontend**: Import from `@inertiajs/react` (router, Link) and `@nordbeam/nb-inertia` (useForm, modals)

### Installation Flow

Install nb_inertia via the installer:

```bash
mix nb_inertia.install --client-framework react --typescript
```

**What to import:**

```typescript
// Official Inertia - router and Link work with RouteResult natively
import { router, Link, usePage } from '@inertiajs/react';

// nb_inertia - useForm with route binding
import { useForm } from '@nordbeam/nb-inertia/react/useForm';

// nb_inertia - SSR-safe components with modal context (when using modals)
import { Head } from '@nordbeam/nb-inertia/react/Head';
import { usePage } from '@nordbeam/nb-inertia/react/usePage';

// nb_inertia - Modal system
import { Modal, ModalLink, ModalProvider } from '@nordbeam/nb-inertia/react/modals';

// nb_routes
import { user_path, update_user_path } from '@/routes';
```

## Enhanced React Components

### router and Link (Use Official Inertia)

**IMPORTANT**: Official `@inertiajs/react` already supports RouteResult objects natively via `UrlMethodPair`.

```typescript
import { router, Link } from '@inertiajs/react';  // Official Inertia!
import { user_path, update_user_path } from '@/routes';

// router.visit accepts RouteResult directly
router.visit(user_path(1));                    // Uses GET
router.visit(update_user_path.patch(1));       // Uses PATCH

// Link href accepts RouteResult directly
<Link href={user_path(1)}>View User</Link>
<Link href={update_user_path.patch(1)}>Edit User</Link>
```

**No wrappers needed** - use official Inertia components directly with nb_routes.

### useForm (React)

**Location**: `priv/nb_inertia/react/useForm.tsx`

Enhanced Inertia useForm hook with optional route binding. When bound to a RouteResult, the submit method automatically uses the route's URL and method.

**Key Features**:
- Optional route binding via second parameter
- Bound forms: `submit()` with no arguments - URL/method from route
- Unbound forms: `submit(method, url, options)` - standard Inertia behavior
- All other useForm features work unchanged (transform, reset, clearErrors, etc.)
- Full TypeScript support with `BoundFormType` and `UnboundFormType`

**Usage**:

```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { update_user_path } from '@/routes';

// Bound to a route - simplified submit()
function EditUser({ user }) {
  const form = useForm(
    { name: user.name, email: user.email },
    update_user_path.patch(user.id)  // Route binding
  );

  const handleSubmit = (e) => {
    e.preventDefault();
    form.submit({  // No method or URL needed!
      preserveScroll: true,
      onSuccess: () => console.log('Saved!'),
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={form.data.name}
        onChange={e => form.setData('name', e.target.value)}
      />
      <button type="submit" disabled={form.processing}>
        Save
      </button>
      {form.errors.name && <div>{form.errors.name}</div>}
    </form>
  );
}

// Unbound - works like standard Inertia
function CreateUser() {
  const form = useForm({ name: '', email: '' });

  const handleSubmit = (e) => {
    e.preventDefault();
    form.submit('post', '/users', {
      onSuccess: () => console.log('Created!'),
    });
  };

  // ... rest of component
}

// All standard useForm features work
form.setData('name', 'John');
form.setData({ name: 'Jane', email: 'jane@example.com' });
form.transform((data) => ({ ...data, timestamp: Date.now() }));
form.reset();
form.clearErrors();

// Check form state
console.log(form.data);
console.log(form.errors);
console.log(form.processing);
console.log(form.wasSuccessful);
console.log(form.isDirty);
```

**TypeScript Types**:

```typescript
export type BoundFormType<TForm> = Omit<InertiaFormType<TForm>, 'submit'> & {
  submit(options?: BoundSubmitOptions): void;
};

export type UnboundFormType<TForm> = InertiaFormType<TForm>;

// Function overloads for proper type inference
export function useForm<TForm>(data: TForm, route?: RouteResult):
  RouteResult extends typeof route ? BoundFormType<TForm> : UnboundFormType<TForm>;
```

## Enhanced Vue Components

### router and Link (Use Official Inertia)

**IMPORTANT**: Official `@inertiajs/vue3` already supports RouteResult objects natively via `UrlMethodPair`.

```vue
<script setup lang="ts">
import { router, Link } from '@inertiajs/vue3';  // Official Inertia!
import { user_path, update_user_path } from '@/routes';

// router.visit accepts RouteResult directly
router.visit(user_path(1));                    // Uses GET
router.visit(update_user_path.patch(1));       // Uses PATCH
</script>

<template>
  <!-- Link href accepts RouteResult directly -->
  <Link :href="user_path(user.id)">View User</Link>
  <Link :href="update_user_path.patch(user.id)">Edit User</Link>
</template>
```

**No wrappers needed** - use official Inertia components directly with nb_routes.

### useForm (Vue)

**Location**: `priv/nb_inertia/vue/useForm.ts`

Enhanced useForm composable for Vue 3 with route binding.

**Usage**:

```vue
<script setup lang="ts">
import { useForm } from '@nordbeam/nb-inertia/vue/useForm';
import { update_user_path } from '@/routes';

const props = defineProps<{ user: User }>();

// Bound to a route
const form = useForm(
  { name: props.user.name, email: props.user.email },
  update_user_path.patch(props.user.id)
);

const handleSubmit = () => {
  form.submit({  // No method or URL needed!
    preserveScroll: true,
    onSuccess: () => console.log('Saved!'),
  });
};
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input v-model="form.data.name" />
    <button type="submit" :disabled="form.processing">Save</button>
    <div v-if="form.errors.name">{{ form.errors.name }}</div>
  </form>
</template>
```

## Integration with nb_routes

### RouteResult Type

All enhanced components understand the RouteResult type from nb_routes rich mode:

```typescript
type RouteResult = {
  url: string;
  method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};
```

### Type Guards

Each component includes a type guard to detect RouteResult objects:

```typescript
function isRouteResult(value: unknown): value is RouteResult {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const obj = value as Record<string, unknown>;

  return (
    typeof obj.url === 'string' &&
    typeof obj.method === 'string' &&
    ['get', 'post', 'put', 'patch', 'delete', 'head'].includes(obj.method)
  );
}
```

### How nb_routes Integration Works

1. **nb_routes generates** route helpers in rich mode:
   ```javascript
   // routes.js
   export const user_path = Object.assign(
     (id, options) => _buildUrl(`/users/${id}`, options),
     {
       get: (id, options) => ({ url: `/users/${id}`, method: 'get' }),
       url: (id, options) => _buildUrl(`/users/${id}`, options)
     }
   );

   export const update_user_path = Object.assign(
     (id, options) => ({ url: `/users/${id}`, method: 'patch' }),
     {
       patch: (id, options) => ({ url: `/users/${id}`, method: 'patch' }),
       url: (id, options) => _buildUrl(`/users/${id}`, options)
     }
   );
   ```

2. **nb_inertia components detect** RouteResult objects:
   ```typescript
   // In Link component
   const finalHref = isRouteResult(href) ? href.url : href;
   const finalMethod = isRouteResult(href) && !method ? href.method : method;
   ```

3. **Seamless usage** in React/Vue:
   ```typescript
   // Both work seamlessly
   <Link href={user_path(1)} />           // { url: "/users/1", method: "get" }
   <Link href={update_user_path.patch(1)} />  // { url: "/users/1", method: "patch" }
   ```

## Shared Props with inertia_shared

### Overview

Shared props are props that should be available on every page in a controller. Use `inertia_shared(SharedPropsModule)` in your controller to automatically merge shared props with page props.

**IMPORTANT**:
- Use `inertia_shared()` in the controller, NOT a plug
- Generated TypeScript page props automatically `extends` the shared props type
- Never manually merge types like `type PageProps = DashboardProps & { auth: AuthProps }` - this is auto-generated

### Step 1: Define SharedProps Module

```elixir
# lib/my_app_web/inertia_shared/auth.ex
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  alias MyAppWeb.Serializers.{UserSerializer, AccountSerializer}

  inertia_shared do
    prop(:user, UserSerializer, nullable: true)
    prop(:account, AccountSerializer, nullable: true)
    prop(:flash, :map)
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    scope = conn.assigns[:current_scope]

    %{
      user: if(scope && scope.user, do: scope.user),
      account: if(scope && scope.user, do: scope.user.account),
      flash: conn.assigns[:flash] || %{}
    }
  end
end
```

### Step 2: Use inertia_shared in Controller

```elixir
defmodule MyAppWeb.DashboardController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  alias MyAppWeb.InertiaShared.Auth

  # This merges Auth props into ALL pages in this controller
  inertia_shared(Auth)

  inertia_page :dashboard do
    # Page-specific props go here
    prop :stats, StatsSerializer
  end

  def index(conn, _params) do
    render_inertia(conn, :dashboard, stats: get_stats())
  end
end
```

### Step 3: Generated TypeScript Types

nb_ts automatically generates types that extend shared props:

```typescript
// assets/js/types/AuthProps.ts (auto-generated)
export interface AuthProps {
  user: User | null;
  account: Account | null;
  flash: Record<string, any>;
}

// assets/js/types/DashboardProps.ts (auto-generated)
import type { AuthProps } from "./AuthProps";

export interface DashboardProps extends AuthProps {
  stats: Stats;
}
```

### Step 4: Frontend Usage

```tsx
// CORRECT: Just import the page props - shared props are already included
import type { DashboardProps } from "@/types";

export default function Dashboard({ user, account, flash, stats }: DashboardProps) {
  // All props are available directly - no manual merging needed
  return (
    <div>
      <h1>Welcome {user?.name}</h1>
      {flash.success && <Alert>{flash.success}</Alert>}
      <StatsDisplay stats={stats} />
    </div>
  );
}
```

```tsx
// WRONG: Never manually merge types - this is redundant
import type { DashboardProps, AuthProps } from "@/types";
type PageProps = DashboardProps & { auth: AuthProps };  // ❌ Don't do this
```

### Multiple Shared Props Modules

You can use multiple shared props modules:

```elixir
defmodule MyAppWeb.AdminController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  alias MyAppWeb.InertiaShared.{Auth, AdminNav}

  inertia_shared(Auth)
  inertia_shared(AdminNav)

  # Both Auth and AdminNav props are merged into all pages
end
```

### Why NOT to Use a Plug

A common mistake is creating a plug to inject shared props:

```elixir
# ❌ WRONG: Don't do this
defmodule MyAppWeb.Plugs.InertiaSharedProps do
  def call(conn, _opts) do
    Inertia.Controller.assign_prop(conn, :auth, Auth.serialize_props(conn))
  end
end
```

This approach:
- Doesn't integrate with nb_ts type generation
- Requires manual type definitions in frontend
- Props aren't validated at compile time

Instead, use `inertia_shared(Auth)` in your controller - it handles serialization, type generation, and validation automatically.

## Usage Patterns

### Pattern 1: Simple Navigation

```typescript
import { router, Link } from '@inertiajs/react';  // Official Inertia!
import { users_path, user_path } from '@/routes';

// Navigate programmatically
router.visit(users_path());

// Navigate with Link
<Link href={user_path(1)}>View User</Link>
```

### Pattern 2: Form with Mutation

```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { create_user_path } from '@/routes';

function CreateUser() {
  const form = useForm(
    { name: '', email: '' },
    create_user_path.post()  // Route binding
  );

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.submit(); }}>
      <input
        value={form.data.name}
        onChange={e => form.setData('name', e.target.value)}
      />
      <button type="submit">Create</button>
    </form>
  );
}
```

### Pattern 3: Mixed RouteResult and Strings

```typescript
import { Link } from '@inertiajs/react';  // Official Inertia!
import { user_path, update_user_path } from '@/routes';

// RouteResult object
<Link href={user_path(1)}>User Profile</Link>

// Plain string (backward compatible)
<Link href="/about">About</Link>

// RouteResult with method variant
<Link href={update_user_path.patch(1)}>Edit</Link>
```

### Pattern 4: Complex Form with nb_serializer

```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { update_post_path } from '@/routes';
import type { Post } from '@/types';

function EditPost({ post }: { post: Post }) {
  const form = useForm(
    {
      title: post.title,
      content: post.content,
      published: post.published
    },
    update_post_path.patch(post.id)
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    form.submit({
      preserveScroll: true,
      onSuccess: () => {
        console.log('Post updated!');
      },
      onError: (errors) => {
        console.error('Validation errors:', errors);
      }
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={form.data.title}
        onChange={e => form.setData('title', e.target.value)}
      />
      {form.errors.title && <div className="error">{form.errors.title}</div>}

      <textarea
        value={form.data.content}
        onChange={e => form.setData('content', e.target.value)}
      />

      <label>
        <input
          type="checkbox"
          checked={form.data.published}
          onChange={e => form.setData('published', e.target.checked)}
        />
        Published
      </label>

      <button type="submit" disabled={form.processing}>
        {form.processing ? 'Saving...' : 'Save'}
      </button>
    </form>
  );
}
```

## Installer Details

### What the Installer Creates

When you run `mix nb_inertia.install --client-framework react --typescript`, it:

1. **Installs npm packages**:
   - `@inertiajs/react` (or vue3/svelte)
   - `@nordbeam/nb-inertia` - Enhanced useForm, Head, usePage, and modal components
   - `react`, `react-dom`, `axios`
   - TypeScript types (if `--typescript`)

2. **Configures Phoenix**:
   - Adds `use NbInertia.Controller` to web.ex
   - Adds `import Inertia.HTML` to web.ex
   - Adds `plug Inertia.Plug` to browser pipeline
   - Updates root layout for Inertia

3. **Sets up TypeScript** (if enabled):
   - Creates `tsconfig.json`
   - Configures path alias `@/*` → `./js/*`
   - Composes `nb_ts.install` for type generation

### What to Import

**Official Inertia** (use directly - supports RouteResult natively):
- `router` and `Link` from `@inertiajs/react` or `@inertiajs/vue3`

**nb_inertia** (enhanced components):
- `useForm` from `@nordbeam/nb-inertia/react/useForm` (route binding)
- `Head` from `@nordbeam/nb-inertia/react/Head` (modal context)
- `usePage` from `@nordbeam/nb-inertia/react/usePage` (modal context)
- Modal components from `@nordbeam/nb-inertia/react/modals`

**Svelte**:
- Standard Inertia setup (enhanced components not yet available for Svelte)

## Important Usage Notes

### Import Guidelines

**For router and Link** - use official Inertia (they support RouteResult natively):

```typescript
import { router, Link } from '@inertiajs/react';  // Official - works with RouteResult!
```

**For useForm with route binding** - use nb_inertia:

```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
```

**For SSR-safe components with modal context** - use nb_inertia:

```typescript
import { Head } from '@nordbeam/nb-inertia/react/Head';
import { usePage } from '@nordbeam/nb-inertia/react/usePage';
```

**For modal system** - use nb_inertia:

```typescript
import { Modal, ModalLink, ModalProvider } from '@nordbeam/nb-inertia/react/modals';
```

### Backward Compatibility

All nb_inertia components are 100% backward compatible with standard Inertia usage:

```typescript
// These all work fine
router.visit('/users/1');
router.get('/users/1');
<Link href="/users/1">View</Link>
form.submit('post', '/users');
```

The enhancement is **additive** - if you pass a RouteResult, it uses the enhanced behavior. If you pass a string, it works exactly like standard Inertia.

### Type Safety

When using TypeScript with nb_routes rich mode and nb_ts:

```typescript
import type { UsersShowProps } from '@/types';  // Generated by nb_ts
import { user_path } from '@/routes';           // Generated by nb_routes
import { Link } from '@inertiajs/react';        // Official Inertia

export default function Show({ user }: UsersShowProps) {
  // Full type safety:
  // - user is typed by nb_ts
  // - user_path is typed by nb_routes
  // - Link accepts RouteResult from user_path (native support!)
  return <Link href={user_path(user.id)}>{user.name}</Link>;
}
```

## Modal and Slideover Support

### Overview

nb_inertia provides a complete modal and slideover system that allows rendering Inertia pages as overlays without full page navigation. This creates a smoother user experience while maintaining the full power of Inertia.js page components.

**Key Components:**
- **Backend**: `NbInertia.Modal` module and `render_inertia_modal/4` macro
- **Frontend**: React and Vue modal components with RouteResult integration
- **Communication**: Custom HTTP headers for modal state
- **Routing**: Integration with nb_routes for type-safe modal links

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Backend (Phoenix)                        │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Controller                                           │    │
│  │   render_inertia_modal(conn, :users_show,          │    │
│  │     [user: user],                                   │    │
│  │     base_url: "/users",                             │    │
│  │     size: :lg)                                      │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ NbInertia.Modal.BaseRenderer                        │    │
│  │   - Builds Modal struct                             │    │
│  │   - Serializes props                                │    │
│  │   - Adds custom headers                             │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ NbInertia.Plugs.ModalHeaders                        │    │
│  │   - Sets X-Inertia-Modal: true                      │    │
│  │   - Sets X-Inertia-Modal-Base-Url                   │    │
│  │   - Sets X-Inertia-Modal-Config (JSON)              │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                     │
└─────────────────────────┼─────────────────────────────────────┘
                          │ HTTP Response with Headers
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                    Frontend (React/Vue)                       │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ModalLink Component                                  │    │
│  │   - Intercepts click                                │    │
│  │   - Fetches page via Inertia                        │    │
│  │   - Reads modal headers                             │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ modalStack.ts                                        │    │
│  │   - Manages modal stack                             │    │
│  │   - Z-index calculation                             │    │
│  │   - History integration                             │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Modal/HeadlessModal Components                      │    │
│  │   - Renders modal UI                                │    │
│  │   - Handles close events                            │    │
│  │   - Applies configuration                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

### Backend Implementation

#### Core Module: `NbInertia.Modal`

**Location**: `lib/nb_inertia/modal.ex`

Provides the Modal data structure and configuration functions:

```elixir
defmodule NbInertia.Modal do
  @type t :: %__MODULE__{
    component: String.t(),
    props: map(),
    base_url: String.t() | nil,
    config: config()
  }

  @type config :: %{
    optional(:size) => :sm | :md | :lg | :xl | :full,
    optional(:position) => :center | :top | :bottom | :left | :right,
    optional(:slideover) => boolean(),
    optional(:closeButton) => boolean(),
    optional(:closeExplicitly) => boolean(),
    optional(:maxWidth) => String.t(),
    optional(:paddingClasses) => String.t(),
    optional(:panelClasses) => String.t(),
    optional(:backdropClasses) => String.t()
  }
end
```

**Key Functions:**
- `new/2` - Create a new Modal struct
- `base_url/2` - Set the base URL for the modal
- `base_route/3` - Set base URL from nb_routes RouteResult
- `size/2`, `position/2`, `slideover/2` - Configure appearance
- `close_button/2`, `close_explicitly/2` - Control close behavior
- CSS customization functions for advanced styling

#### BaseRenderer: `NbInertia.Modal.BaseRenderer`

**Location**: `lib/nb_inertia/modal/base_renderer.ex`

Handles rendering Modal structs to Inertia responses:

```elixir
defmodule NbInertia.Modal.BaseRenderer do
  def render(conn, modal) do
    conn
    |> prepare_props(modal.props)
    |> add_modal_headers(modal)
    |> render_inertia_response(modal.component, modal.props)
  end

  defp add_modal_headers(conn, modal) do
    conn
    |> put_resp_header("x-inertia-modal", "true")
    |> put_resp_header("x-inertia-modal-base-url", modal.base_url || "/")
    |> put_resp_header("x-inertia-modal-config", Jason.encode!(modal.config))
  end
end
```

#### Redirector: `NbInertia.Modal.Redirector`

**Location**: `lib/nb_inertia/modal/redirector.ex`

Provides `redirect_modal/2` for redirecting from within modal workflows:

```elixir
defmodule NbInertia.Modal.Redirector do
  def redirect_modal(conn, opts) do
    url = Keyword.fetch!(opts, :to)

    conn
    |> put_resp_header("x-inertia-modal-redirect", url)
    |> redirect(to: url)
  end
end
```

#### Modal Headers Plug: `NbInertia.Plugs.ModalHeaders`

**Location**: `lib/nb_inertia/plugs/modal_headers.ex`

Detects modal requests and sets up the response pipeline:

```elixir
defmodule NbInertia.Plugs.ModalHeaders do
  def modal_headers(conn, _opts) do
    if get_req_header(conn, "x-inertia-modal-request") == ["true"] do
      register_before_send(conn, &add_modal_response_headers/1)
    else
      conn
    end
  end

  defp add_modal_response_headers(conn) do
    # Ensure modal headers are preserved in response
    conn
  end
end
```

#### Controller Integration

**Location**: `lib/nb_inertia/controller.ex`

The `render_inertia_modal/4` macro is defined in `NbInertia.Controller`:

```elixir
defmacro render_inertia_modal(conn, page_name, props, opts \\ []) do
  quote do
    modal =
      NbInertia.Modal.new(
        infer_component_name(unquote(page_name)),
        unquote(props)
      )
      |> apply_modal_opts(unquote(opts))

    NbInertia.Modal.BaseRenderer.render(unquote(conn), modal)
  end
end

defp apply_modal_opts(modal, opts) do
  Enum.reduce(opts, modal, fn
    {:base_url, url}, acc -> NbInertia.Modal.base_url(acc, url)
    {:size, size}, acc -> NbInertia.Modal.size(acc, size)
    {:position, pos}, acc -> NbInertia.Modal.position(acc, pos)
    {:slideover, val}, acc -> NbInertia.Modal.slideover(acc, val)
    # ... other options
  end)
end
```

### Frontend Implementation

#### React Components

##### HeadlessModal.tsx

**Location**: `priv/nb_inertia/react/modals/HeadlessModal.tsx`

Headless modal component that manages modal state and stack:

**Key Features:**
- Manages modal stack via `modalStack.ts`
- Handles browser history integration
- Provides modal context (index, base URL, config)
- Renders children with `(modal, close)` signature

**Props:**
```typescript
export interface HeadlessModalProps {
  component: React.ComponentType<any>;
  componentProps?: Record<string, any>;
  baseUrl: string;
  config?: ModalConfig;
  open?: boolean;
  onClose?: () => void;
  children?: (modal: ModalContext, close: () => void) => React.ReactNode;
}
```

##### Modal.tsx

**Location**: `priv/nb_inertia/react/modals/Modal.tsx`

Styled modal component using Radix UI Dialog:

**Features:**
- Wraps HeadlessModal with UI layer
- Uses Radix UI Dialog primitives
- Supports both modal and slideover variants
- Automatic z-index management based on stack position
- Optional close button
- Configurable backdrop, panel, and content styling

**Components:**
- `ModalContent.tsx` - Centered modal content wrapper
- `SlideoverContent.tsx` - Slideover content wrapper
- `CloseButton.tsx` - Styled close button

##### ModalLink.tsx

**Location**: `priv/nb_inertia/react/modals/ModalLink.tsx`

Link component that opens pages as modals:

**Features:**
- Accepts string URLs or nb_routes RouteResult objects
- Intercepts clicks to prevent navigation
- Fetches target page via Inertia router
- Detects `_nb_modal` prop and defers to InitialModalHandler (for `render_inertia_modal` responses)
- Falls back to legacy flow (pushes page component directly) for non-modal responses
- Shows loading state during fetch
- Respects modifier keys (Ctrl/Cmd for new tab)

**Important Implementation Detail:**

When the backend uses `render_inertia_modal/4`, the response includes a `_nb_modal` prop. ModalLink detects this and returns early, allowing InitialModalHandler to handle pushing the modal. This prevents duplicate modals from being created.

```typescript
// In onSuccess callback:
if (pageProps._nb_modal) {
  // Modal response - let InitialModalHandler handle it
  setIsLoading(false);
  return;
}
// Legacy flow for non-modal responses...
```

**Usage Pattern:**
```typescript
<ModalLink
  href={user_path(user.id)}  // RouteResult from nb_routes
  modalConfig={{ size: 'lg', position: 'center' }}
>
  View User
</ModalLink>
```

##### InitialModalHandler

**Required Setup Component**

InitialModalHandler must be rendered inside the Inertia App context. It handles:
1. Initial page load with `_nb_modal` prop (direct URL access to modal)
2. Navigation events that include modal data from `render_inertia_modal`

**Key Implementation Details:**

- Tracks the current modal in a ref (`currentModalRef`) to prevent duplicate pushes
- **Must clear `currentModalRef` in `onClose` callback** to allow reopening the same modal
- Uses `history.replaceState` on close to update URL without triggering Inertia navigation

```typescript
// Example InitialModalHandler onClose callback:
onClose: () => {
  // IMPORTANT: Clear ref so the same modal can be opened again
  currentModalRef.current = null;

  // Update URL to base URL when modal is closed
  if (modalOnBase.baseUrl && typeof window !== "undefined") {
    if (window.location.pathname !== modalOnBase.baseUrl) {
      window.history.replaceState({}, "", modalOnBase.baseUrl);
    }
  }
},
```

**Why this matters:** When closing a modal via `history.replaceState`, no Inertia navigate event fires. Without clearing `currentModalRef`, the duplicate detection logic would prevent the same modal from opening again.

##### modalStack.ts

**Location**: `priv/nb_inertia/react/modals/modalStack.ts`

Manages the modal stack with React context:

**Key Responsibilities:**
- Track active modals in a stack (array)
- Calculate z-index for each modal
- Integrate with browser history API
- Provide `pushModal`, `popModal`, `closeModal` functions
- Handle modal navigation and redirects

**Context Structure:**
```typescript
interface ModalStackContext {
  modals: Modal[];
  pushModal: (modal: ModalData) => void;
  popModal: () => void;
  closeModal: (index: number) => void;
  clearModals: () => void;
}
```

#### Vue Components

##### HeadlessModal.vue

**Location**: `priv/nb_inertia/vue/modals/HeadlessModal.vue`

Vue 3 composition API modal manager:

**Features:**
- Uses Vue 3 `<script setup>` syntax
- Manages modal stack with composables
- Provides scoped slots for rendering
- History integration with Vue Router

##### Modal.vue

**Location**: `priv/nb_inertia/vue/modals/Modal.vue`

Styled modal using Headless UI:

**Features:**
- Uses `@headlessui/vue` Dialog component
- Supports Teleport for portal rendering
- Reactive modal configuration
- Scoped slot for content with `close` function

##### ModalLink.vue

**Location**: `priv/nb_inertia/vue/modals/ModalLink.vue`

Vue modal link component:

**Features:**
- Template ref for link element
- Event handling with Vue event modifiers
- Reactive loading state
- Integration with Vue Inertia router

##### modalStack.ts (Vue)

**Location**: `priv/nb_inertia/vue/modals/modalStack.ts`

Vue composable for modal stack management:

```typescript
export function useModalStack() {
  const modals = ref<Modal[]>([]);

  const pushModal = (data: ModalData) => {
    modals.value.push({
      ...data,
      index: modals.value.length
    });
  };

  const popModal = () => {
    modals.value.pop();
  };

  return { modals, pushModal, popModal, closeModal };
}
```

### HTTP Headers

The modal system uses custom HTTP headers for communication:

#### Request Headers

- `X-Inertia-Modal-Request: true` - Indicates request is for a modal

#### Response Headers

- `X-Inertia-Modal: true` - Indicates response is a modal
- `X-Inertia-Modal-Base-Url: /users` - Base URL for modal backdrop
- `X-Inertia-Modal-Config: {...}` - JSON configuration object
- `X-Inertia-Modal-Redirect: /users` - Redirect URL (when redirecting from modal)

**Example Response:**
```http
HTTP/1.1 200 OK
X-Inertia: true
X-Inertia-Modal: true
X-Inertia-Modal-Base-Url: /users
X-Inertia-Modal-Config: {"size":"lg","position":"center","closeButton":true}
Content-Type: application/json

{
  "component": "Users/Show",
  "props": { "user": { "id": 1, "name": "Alice" } },
  "url": "/users/1",
  "version": "..."
}
```

### Integration with nb_routes

The modal system integrates seamlessly with nb_routes rich mode:

#### Backend Integration

```elixir
# Using RouteResult for base_url
alias NbRoutes.Helpers, as: Routes

modal =
  Modal.new("Users/Show", %{user: user})
  |> Modal.base_route(Routes.users_path())  # Uses RouteResult
```

#### Frontend Integration

```typescript
import { ModalLink } from '@/modals/ModalLink';
import { user_path } from '@/routes';

// RouteResult object automatically handled
<ModalLink href={user_path(user.id)}>View User</ModalLink>
```

### Modal Stack and Z-Index Management

**Z-Index Calculation:**
```typescript
const baseZIndex = 50;
const getZIndex = (index: number) => baseZIndex + index;

// Modal 0: z-index 50 (backdrop) and 51 (content)
// Modal 1: z-index 51 (backdrop) and 52 (content)
// Modal 2: z-index 52 (backdrop) and 53 (content)
```

This ensures proper layering of nested modals.

### History Integration

Modals integrate with browser history to allow back/forward navigation:

1. When modal opens: Push state to history
2. When user clicks back: Close modal
3. When modal closes: Replace current state with base URL
4. Multiple modals: Each has its own history entry

**Implementation (React):**
```typescript
useEffect(() => {
  const handlePopState = () => {
    if (modals.length > 0) {
      popModal();
    }
  };

  window.addEventListener('popstate', handlePopState);
  return () => window.removeEventListener('popstate', handlePopState);
}, [modals]);
```

### Configuration System

#### Default Configuration

**Location**: `priv/templates/nb_inertia_modal.exs`

Template for modal configuration file that installer generates:

```elixir
config :nb_inertia, :modal,
  default_size: :md,
  default_position: :center,
  default_close_button: true,
  default_close_explicitly: false,
  default_padding_classes: "p-6",
  default_panel_classes: "bg-white rounded-lg shadow-xl",
  default_backdrop_classes: "bg-black/50"

config :nb_inertia, :slideover,
  default_position: :right,
  default_size: :md
```

#### Configuration Hierarchy

1. **Global defaults** (from config file)
2. **Per-modal config** (passed to `render_inertia_modal/4`)
3. **Frontend overrides** (via `config` prop in components)

### Testing Modal Features

#### Backend Tests

Test modal rendering:

```elixir
test "renders modal with configuration", %{conn: conn} do
  conn = inertia_get(conn, ~p"/users/1?modal=true")

  assert_inertia_page(conn, "Users/Show")
  assert get_resp_header(conn, "x-inertia-modal") == ["true"]
  assert get_resp_header(conn, "x-inertia-modal-base-url") == ["/users"]

  config = conn
    |> get_resp_header("x-inertia-modal-config")
    |> List.first()
    |> Jason.decode!()

  assert config["size"] == "lg"
  assert config["position"] == "center"
end
```

#### Frontend Tests

Test modal components:

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { Modal } from '@/modals/Modal';

test('renders modal with close button', () => {
  const handleClose = jest.fn();

  render(
    <Modal
      baseUrl="/users"
      config={{ size: 'lg', closeButton: true }}
      onClose={handleClose}
    >
      {(close) => (
        <div>
          <h2>Modal Content</h2>
          <button onClick={close}>Close</button>
        </div>
      )}
    </Modal>
  );

  expect(screen.getByText('Modal Content')).toBeInTheDocument();

  fireEvent.click(screen.getByText('Close'));
  expect(handleClose).toHaveBeenCalled();
});
```

### Performance Considerations

1. **Lazy Loading**: Modal components should be lazy loaded:
   ```typescript
   const UserModal = lazy(() => import('./modals/UserModal'));
   ```

2. **Stack Cleanup**: Always clean up modal stack on navigation:
   ```typescript
   router.on('navigate', () => {
     clearModals();
   });
   ```

3. **Props Serialization**: Use nb_serializer for efficient modal prop serialization

4. **Z-Index Limits**: Stack supports up to 100 nested modals (z-index 50-150)

### Common Patterns

#### Confirmation Modal

```elixir
def delete(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  render_inertia_modal(conn, :confirm_delete,
    [user: user, action: delete_user_path(conn, :destroy, id)],
    base_url: users_path(conn, :index),
    size: :sm,
    close_explicitly: true
  )
end
```

#### Form Modal with Validation

```elixir
def create(conn, %{"user" => params}) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created")
      |> redirect_modal(to: user_path(conn, :show, user))

    {:error, changeset} ->
      render_inertia_modal(conn, :new_user,
        [changeset: changeset],
        base_url: users_path(conn, :index),
        size: :lg
      )
  end
end
```

#### Multi-Step Modal

```elixir
def edit(conn, %{"id" => id, "step" => step}) do
  user = Accounts.get_user!(id)

  render_inertia_modal(conn, :edit_user,
    [user: user, step: step, total_steps: 3],
    base_url: user_path(conn, :show, id),
    size: :xl,
    close_explicitly: true
  )
end
```

## Real-Time WebSocket Support

### Overview

nb_inertia provides real-time prop updates via Phoenix Channels, eliminating the need for polling. This integration leverages Phoenix's excellent WebSocket support while maintaining Inertia.js's prop-based architecture.

### Installation

Run the generator to set up WebSocket support:

```bash
mix nb_inertia.gen.realtime
```

This creates:
- `lib/my_app_web/channels/user_socket.ex` - Phoenix Socket module
- `assets/js/lib/socket.{ts,js}` - Socket setup with React hooks
- Socket route in your endpoint

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Phoenix Backend                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Phoenix Channel                                          │   │
│  │   def join("chat:" <> room_id, _params, socket)         │   │
│  │   # Standard Phoenix Channel                             │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         │ broadcast/3                            │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ NbInertia.Realtime (optional helper)                    │   │
│  │   broadcast(Endpoint, topic, event,                     │   │
│  │     message: {MessageSerializer, message})              │   │
│  │   # Same serialization as render_inertia                │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │ WebSocket
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend (React)                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ useChannel Hook                                          │   │
│  │   useChannel(socket, `chat:\${room.id}`, {              │   │
│  │     message_created: ({ message }) => { ... }           │   │
│  │   });                                                    │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ useRealtimeProps Hook                                    │   │
│  │   const { props, setProp } = useRealtimeProps();        │   │
│  │   setProp('messages', msgs => [...msgs, message]);      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Implementation

#### Standard Phoenix Channels

No special backend integration required. Use standard Phoenix Channels:

```elixir
# lib/my_app_web/channels/chat_channel.ex
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  def join("chat:" <> room_id, _params, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end
end

# lib/my_app_web/channels/user_socket.ex
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  channel "chat:*", MyAppWeb.ChatChannel

  def connect(_params, socket, _connect_info), do: {:ok, socket}
  def id(_socket), do: nil
end
```

#### Broadcasting Updates

Use standard Phoenix broadcasting:

```elixir
defmodule MyApp.Chat do
  def create_message(room, attrs) do
    {:ok, message} = Repo.insert(Message.changeset(attrs))

    # Standard Phoenix broadcast
    MyAppWeb.Endpoint.broadcast("chat:#{room.id}", "message_created", %{
      message: MyApp.Serializers.MessageSerializer.serialize(message)
    })

    {:ok, message}
  end
end
```

Or use the `NbInertia.Realtime` helper for consistent serialization:

```elixir
defmodule MyApp.Chat do
  import NbInertia.Realtime

  def create_message(room, attrs) do
    {:ok, message} = Repo.insert(Message.changeset(attrs))

    # Uses same tuple serialization as render_inertia
    broadcast(MyAppWeb.Endpoint, "chat:#{room.id}", "message_created",
      message: {MyApp.Serializers.MessageSerializer, message}
    )

    {:ok, message}
  end
end
```

### Frontend Implementation

#### Level 1: Simple (Like Rails)

```typescript
import { socket, useChannel, useRealtimeProps } from '@/lib/socket';

export default function ChatRoom({ room }: ChatRoomProps) {
  const { props, setProp } = useRealtimeProps<ChatRoomProps>();

  useChannel(socket, `chat:${room.id}`, {
    message_created: ({ message }) => {
      setProp('messages', msgs => [...msgs, message]);
    },
    message_deleted: ({ id }) => {
      setProp('messages', msgs => msgs.filter(m => m.id !== id));
    }
  });

  return (
    <div>
      {props.messages.map(msg => (
        <Message key={msg.id} message={msg} />
      ))}
    </div>
  );
}
```

#### Level 2: Type-Safe Events

```typescript
import { socket, useChannel, useRealtimeProps } from '@/lib/socket';
import type { ChatEvents, ChatRoomProps } from '@/types';

export default function ChatRoom({ room }: ChatRoomProps) {
  const { props, setProp } = useRealtimeProps<ChatRoomProps>();

  useChannel<ChatEvents>(socket, `chat:${room.id}`, {
    message_created: ({ message }) => {
      // message is typed!
      setProp('messages', msgs => [...msgs, message]);
    }
  });

  return <div>{props.messages.map(...)}</div>;
}
```

#### Level 3: Declarative Strategies

For complex apps, use `useChannelProps` for declarative event handling:

```typescript
import { socket, useChannelProps } from '@/lib/socket';
import type { ChatEvents, ChatRoomProps } from '@/types';

export default function ChatRoom({ room }: ChatRoomProps) {
  const { props } = useChannelProps<ChatRoomProps, ChatEvents>(
    socket,
    `chat:${room.id}`,
    {
      // Append new message to array
      message_created: {
        prop: 'messages',
        strategy: 'append',
        transform: e => e.message
      },

      // Remove message from array
      message_deleted: {
        prop: 'messages',
        strategy: 'remove',
        match: (msg, event) => msg.id === event.id
      },

      // Update message in place
      message_edited: {
        prop: 'messages',
        strategy: 'update',
        key: 'id',
        transform: e => e.message
      },

      // Replace entire prop
      room_updated: {
        prop: 'room',
        strategy: 'replace',
        transform: e => e.room
      },

      // Reload from server
      major_change: {
        prop: 'messages',
        strategy: 'reload',
        only: ['messages', 'room']
      }
    }
  );

  return <div>{props.messages.map(...)}</div>;
}
```

#### Level 4: Mixed Approach

```typescript
useChannelProps<ChatRoomProps, ChatEvents>(socket, `chat:${room.id}`, {
  // Declarative for simple cases
  message_created: {
    prop: 'messages',
    strategy: 'append',
    transform: e => e.message
  },

  // Custom handler for complex logic
  presence_changed: (event, { props, setProp, reload }) => {
    if (event.userCount > 100) {
      // Too many users, fall back to polling
      reload({ only: ['messages'] });
    } else {
      setProp('onlineUsers', event.users);
    }
  }
});
```

### Available Strategies

| Strategy | Description |
|----------|-------------|
| `append` | Add item to end of array |
| `prepend` | Add item to start of array |
| `remove` | Remove items matching predicate |
| `update` | Update item in place by key |
| `upsert` | Update if exists, append if not |
| `replace` | Replace entire prop value |
| `reload` | Reload prop(s) from server |

### Hooks Reference

#### useChannel

```typescript
function useChannel<TEvents>(
  socket: Socket | null,
  topic: string,
  handlers: { [K in keyof TEvents]?: (payload: TEvents[K]) => void },
  options?: {
    params?: Record<string, unknown>;
    onJoin?: (response: unknown) => void;
    onError?: (error: unknown) => void;
    onClose?: () => void;
    enabled?: boolean;
  }
): Channel | null;
```

#### useRealtimeProps

```typescript
function useRealtimeProps<T>(): {
  props: T;
  setProp: <K extends keyof T>(key: K, updater: T[K] | ((current: T[K]) => T[K])) => void;
  setProps: (updater: Partial<T> | ((current: T) => Partial<T>)) => void;
  reload: (options?: { only?: string[] }) => void;
  resetOptimistic: () => void;
  hasOptimisticUpdates: boolean;
};
```

#### usePresence

```typescript
function usePresence<T>(
  socket: Socket | null,
  topic: string,
  options?: PresenceOptions
): {
  presences: PresenceState<T>;
  list: () => Array<{ id: string; metas: T[] }>;
  getByKey: (key: string) => T[] | undefined;
};
```

### NbInertia.Realtime Module

**Location**: `lib/nb_inertia/realtime.ex`

Helper module for broadcasting with consistent serialization:

```elixir
# Import in a context module
defmodule MyApp.Chat do
  use NbInertia.Realtime, endpoint: MyAppWeb.Endpoint

  def create_message(room, attrs) do
    {:ok, message} = Repo.insert(...)

    # Endpoint is pre-configured
    broadcast("chat:#{room.id}", "message_created",
      message: {MessageSerializer, message}
    )

    {:ok, message}
  end
end
```

**Functions:**
- `broadcast/4` - Broadcast with serialization support
- `broadcast_from/4` - Broadcast excluding sender
- `serialize_payload/1` - Serialize payload map

### Comparison with Rails/Inertia

| Aspect | Rails + Inertia | Phoenix + nb_inertia |
|--------|-----------------|----------------------|
| Backend channel | ActionCable (standard) | Phoenix Channel (standard) |
| Broadcasting | `ActionCable.server.broadcast` | `Endpoint.broadcast` |
| Frontend subscribe | Manual setup | `useChannel` hook |
| Prop updates | `router.replace({ props })` | `setProp` / `setProps` |
| Type safety | Manual | Auto-generated |
| Declarative patterns | None | Optional strategies |
| Reconnection | ActionCable handles | Phoenix Socket handles |
| Presence | Separate library | Built-in `usePresence` |

## Related Resources

- **Source**: https://github.com/nordbeam/nb/tree/main/nb_inertia
- **Inertia.js docs**: https://inertiajs.com
- **Phoenix Channels**: https://hexdocs.pm/phoenix/channels.html
- **nb_routes integration**: ../nb_routes/CLAUDE.md
- **nb_ts integration**: ../nb_ts/CLAUDE.md
- **Monorepo CLAUDE.md**: ../CLAUDE.md
