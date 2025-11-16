# CLAUDE.md - nb_inertia

Developer guidance for Claude Code when working with the nb_inertia package.

## Package Overview

**nb_inertia** provides advanced Inertia.js integration for Phoenix with declarative page DSL, type-safe props, and enhanced client-side components that seamlessly integrate with nb_routes.

**Location**: `/Users/assim/Projects/nb/nb_inertia`

## Key Features

- **Declarative Page DSL**: Define Inertia pages with compile-time prop validation
- **Type-Safe Props**: Automatic TypeScript type generation via nb_ts integration
- **Enhanced Components**: Wayfinder-style React/Vue components that accept nb_routes RouteResult objects
- **Shared Props**: Automatically add props to all Inertia responses
- **SSR Support**: Optional server-side rendering with DenoRider
- **Optional Dependencies**: Works with or without nb_serializer, nb_routes, and nb_ts

## Architecture

### Core Components

1. **NbInertia.Controller** (`lib/nb_inertia/controller.ex`)
   - Declarative `inertia_page` macro for defining pages
   - Prop validation and serialization
   - Integration with nb_serializer and nb_ts

2. **Enhanced Client Components** (`priv/nb_inertia/`)
   - React: `router.tsx`, `Link.tsx`, `useForm.tsx`
   - Vue: `router.ts`, `Link.vue`, `useForm.ts`
   - Automatic nb_routes RouteResult integration

3. **Installer** (`lib/mix/tasks/nb_inertia.install.ex`)
   - Igniter-based automated setup
   - Creates `assets/js/lib/inertia.{ts,js}` with enhanced exports
   - Configures nb_vite, nb_ts, and esbuild

## Wayfinder-Style Integration

### Concept

nb_inertia provides enhanced Inertia.js components that seamlessly integrate with nb_routes rich mode. This "Wayfinder-style" integration allows you to pass RouteResult objects (which contain both URL and HTTP method) directly to Inertia components, eliminating the need to manually specify methods.

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
│  │ assets/js/lib/inertia.ts (nb_inertia installer)         │   │
│  │   // Re-exports enhanced components                     │   │
│  │   export { router } from '@nordbeam/nb-inertia/react'   │   │
│  │   export { Link } from '@nordbeam/nb-inertia/react'     │   │
│  │   export { useForm } from '@nordbeam/nb-inertia/react'  │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ React Component (assets/js/pages/Users/Show.tsx)        │   │
│  │                                                          │   │
│  │   import { router, Link } from '@/lib/inertia';         │   │
│  │   import { user_path } from '@/routes';                 │   │
│  │   import type { UsersShowProps } from '@/types';        │   │
│  │                                                          │   │
│  │   export default function Show({ user }: UsersShowProps)│   │
│  │     // RouteResult object works seamlessly              │   │
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
- **What it does**: Provides enhanced Inertia.js components that consume RouteResult objects
- **Output**: `lib/inertia.ts` that re-exports enhanced components from `@nordbeam/nb-inertia`
- **Key components**: `router`, `Link`, `useForm` - all accept RouteResult or string URLs

#### nb_ts
- **What it does**: Generates TypeScript types for Inertia page props and serializers
- **Output**: `types/index.ts` with prop interfaces
- **Integration**: Works with nb_inertia's page DSL to generate accurate types

### How They Work Together

1. **Backend**: Define routes in Phoenix router
2. **nb_routes**: Generates route helpers that return RouteResult objects
3. **nb_inertia**: Backend DSL defines props, installer creates lib/inertia.ts
4. **nb_ts**: Generates TypeScript types for props
5. **Frontend**: Import enhanced components from `@/lib/inertia` and use with route helpers

### Installation Flow

The nb_inertia installer automatically creates the integration layer:

```bash
mix nb_inertia.install --client-framework react --typescript
```

This creates `assets/js/lib/inertia.ts`:

```typescript
// Enhanced Inertia.js integration with nb_routes support (React)
//
// This file re-exports enhanced components from nb_inertia that provide
// automatic integration with nb_routes rich mode. Import from this file
// instead of @inertiajs/react to get the enhanced functionality.

export { router } from '@nordbeam/nb-inertia/react/router';
export { Link } from '@nordbeam/nb-inertia/react/Link';
export { useForm } from '@nordbeam/nb-inertia/react/useForm';

// Re-export everything else from Inertia
export * from '@inertiajs/react';
```

## Enhanced React Components

### router (React)

**Location**: `priv/nb_inertia/react/router.tsx`

Enhanced Inertia router that accepts both string URLs and RouteResult objects.

**Key Features**:
- Accepts `RouteResult` objects from nb_routes rich mode
- Automatically extracts URL and method from RouteResult
- Falls back to standard string URL behavior
- All router methods enhanced: `visit`, `get`, `post`, `patch`, `put`, `delete`

**Usage**:

```typescript
import { router } from '@/lib/inertia';
import { user_path, update_user_path } from '@/routes';

// With RouteResult - method auto-detected from route
router.visit(user_path(1));                    // Uses GET
router.visit(update_user_path.patch(1));       // Uses PATCH

// Still works with plain strings
router.visit('/users/1');
router.get('/users/1');
router.post('/users', { name: 'John' });
```

**How it works**:
1. Type guard checks if argument is RouteResult: `{ url: string, method: string }`
2. If RouteResult: extracts `url` and `method`, passes to Inertia router
3. If string: passes through to Inertia router unchanged
4. Fully backward compatible with standard Inertia.js

### Link (React)

**Location**: `priv/nb_inertia/react/Link.tsx`

Enhanced Inertia Link component that accepts RouteResult objects in the `href` prop.

**Key Features**:
- Accepts `RouteResult` objects or string URLs in `href` prop
- Automatically extracts URL and method from RouteResult
- All other Inertia Link props work unchanged (preserveState, data, etc.)
- Full TypeScript support with `EnhancedLinkProps`

**Usage**:

```typescript
import { Link } from '@/lib/inertia';
import { user_path, update_user_path, delete_user_path } from '@/routes';

// With RouteResult objects
<Link href={user_path(1)}>View User</Link>
<Link href={update_user_path.patch(1)}>Edit User</Link>
<Link href={delete_user_path.delete(1)} as="button">Delete</Link>

// Still works with plain strings
<Link href="/users/1">View User</Link>
<Link href="/users/1" method="patch">Edit User</Link>

// With additional Inertia options
<Link
  href={user_path(1)}
  preserveState
  preserveScroll
  only={['user']}
>
  View User
</Link>

// With data for mutations
<Link
  href={update_user_path.patch(1)}
  data={{ name: 'Updated Name' }}
  preserveScroll
>
  Update Name
</Link>
```

**TypeScript Types**:

```typescript
export type EnhancedLinkProps = Omit<InertiaLinkProps, 'href'> & {
  href: string | RouteResult;
};

export type RouteResult = {
  url: string;
  method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};
```

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
import { useForm } from '@/lib/inertia';
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

### router (Vue)

**Location**: `priv/nb_inertia/vue/router.ts`

Enhanced Inertia router for Vue 3 that accepts RouteResult objects.

**Usage**:

```typescript
import { router } from '@/lib/inertia';
import { user_path, update_user_path } from '@/routes';

// With RouteResult objects
router.visit(user_path(1));                    // Uses GET
router.visit(update_user_path.patch(1));       // Uses PATCH

// Still works with plain strings
router.visit('/users/1');
router.get('/users/1');
```

### Link (Vue)

**Location**: `priv/nb_inertia/vue/Link.vue`

Enhanced Inertia Link component for Vue 3.

**Usage**:

```vue
<script setup lang="ts">
import { Link } from '@/lib/inertia';
import { user_path, update_user_path } from '@/routes';
</script>

<template>
  <!-- With RouteResult objects -->
  <Link :href="user_path(user.id)">View User</Link>
  <Link :href="update_user_path.patch(user.id)">Edit User</Link>

  <!-- Still works with plain strings -->
  <Link href="/users/1">View User</Link>
</template>
```

### useForm (Vue)

**Location**: `priv/nb_inertia/vue/useForm.ts`

Enhanced useForm composable for Vue 3 with route binding.

**Usage**:

```vue
<script setup lang="ts">
import { useForm } from '@/lib/inertia';
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

## Usage Patterns

### Pattern 1: Simple Navigation

```typescript
import { router, Link } from '@/lib/inertia';
import { users_path, user_path } from '@/routes';

// Navigate programmatically
router.visit(users_path());

// Navigate with Link
<Link href={user_path(1)}>View User</Link>
```

### Pattern 2: Form with Mutation

```typescript
import { useForm } from '@/lib/inertia';
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
import { Link } from '@/lib/inertia';
import { user_path } from '@/routes';

// RouteResult object
<Link href={user_path(1)}>User Profile</Link>

// Plain string (backward compatible)
<Link href="/about">About</Link>

// RouteResult with method variant
<Link href={update_user_path.patch(1)}>Edit</Link>
```

### Pattern 4: Complex Form with nb_serializer

```typescript
import { useForm } from '@/lib/inertia';
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
   - `@nordbeam/nb-inertia` - Enhanced components package
   - `react`, `react-dom`, `axios`
   - TypeScript types (if `--typescript`)

2. **Creates lib/inertia.ts**:
   ```typescript
   export { router } from '@nordbeam/nb-inertia/react/router';
   export { Link } from '@nordbeam/nb-inertia/react/Link';
   export { useForm } from '@nordbeam/nb-inertia/react/useForm';
   export * from '@inertiajs/react';
   ```

3. **Configures Phoenix**:
   - Adds `use NbInertia.Controller` to web.ex
   - Adds `import Inertia.HTML` to web.ex
   - Adds `plug Inertia.Plug` to browser pipeline
   - Updates root layout for Inertia

4. **Sets up TypeScript** (if enabled):
   - Creates `tsconfig.json`
   - Configures path alias `@/*` → `./js/*`
   - Composes `nb_ts.install` for type generation

### Framework-Specific Files

**React**:
- Creates: `assets/js/lib/inertia.ts` (or `.js`)
- Imports from: `@nordbeam/nb-inertia/react/*`

**Vue**:
- Creates: `assets/js/lib/inertia.ts` (or `.js`)
- Imports from: `@nordbeam/nb-inertia/vue/*`

**Svelte**:
- Standard Inertia setup (enhanced components not yet available for Svelte)

## Important Usage Notes

### Always Import from @/lib/inertia

**DO** import enhanced components from `@/lib/inertia`:

```typescript
import { router, Link, useForm } from '@/lib/inertia';
```

**DON'T** import directly from `@inertiajs/react`:

```typescript
// This bypasses nb_routes integration!
import { router, Link, useForm } from '@inertiajs/react';
```

### Backward Compatibility

All enhanced components are 100% backward compatible with standard Inertia usage:

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
import { Link } from '@/lib/inertia';           // Enhanced component

export default function Show({ user }: UsersShowProps) {
  // Full type safety:
  // - user is typed by nb_ts
  // - user_path is typed by nb_routes
  // - Link accepts RouteResult from user_path
  return <Link href={user_path(user.id)}>{user.name}</Link>;
}
```

## Related Resources

- **Source**: https://github.com/nordbeam/nb/tree/main/nb_inertia
- **Inertia.js docs**: https://inertiajs.com
- **nb_routes integration**: ../nb_routes/CLAUDE.md
- **nb_ts integration**: ../nb_ts/CLAUDE.md
- **Monorepo CLAUDE.md**: ../CLAUDE.md
