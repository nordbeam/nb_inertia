# React vs Vue Implementation Comparison

This document compares the React and Vue implementations of the enhanced NbInertia components, highlighting key differences and design decisions.

## Architecture Overview

Both implementations provide the same core functionality:
- Enhanced router that accepts RouteResult objects
- Enhanced Link component with RouteResult support
- Enhanced useForm with optional route binding

However, they differ in implementation details due to framework-specific patterns.

## File Structure

### React Implementation
```
react/
├── router.tsx           # Enhanced router wrapper
├── Link.tsx             # Enhanced Link component
├── useForm.tsx          # Enhanced useForm hook
├── __tests__/
│   ├── router.test.tsx
│   ├── Link.test.tsx
│   └── useForm.test.tsx
├── package.json
├── vitest.config.ts
├── vitest.setup.ts
└── tsconfig.json
```

### Vue Implementation
```
vue/
├── router.ts            # Enhanced router wrapper
├── Link.vue             # Enhanced Link component (SFC)
├── useForm.ts           # Enhanced useForm composable
├── __tests__/
│   ├── router.test.ts
│   ├── Link.test.ts
│   └── useForm.test.ts
├── package.json
├── vitest.config.ts
├── vitest.setup.ts
└── tsconfig.json
```

## Component Implementation Details

### 1. Router

**Similarities:**
- Identical type definitions for RouteResult
- Same type guard logic
- Same helper functions (normalizeUrl, extractMethod, isRouteResult)
- Identical API surface

**Differences:**
- React: Imports from `@inertiajs/react`
- Vue: Imports from `@inertiajs/vue3`
- File extension: `.tsx` vs `.ts`

**Code Comparison:**

```typescript
// Both have identical structure:
export const router = {
  ...inertiaRouter,

  visit(urlOrRoute: string | RouteResult, options: VisitOptions = {}) {
    const url = normalizeUrl(urlOrRoute);
    const finalOptions: VisitOptions = isRouteResult(urlOrRoute) && !options.method
      ? { ...options, method: urlOrRoute.method }
      : options;
    return inertiaRouter.visit(url, finalOptions);
  },

  // ... other methods identical
};
```

### 2. Link Component

**React Implementation (`Link.tsx`):**
```tsx
import React from 'react';
import { Link as InertiaLink, type InertiaLinkProps } from '@inertiajs/react';

export type EnhancedLinkProps = Omit<InertiaLinkProps, 'href'> & {
  href: string | RouteResult;
};

export const Link: React.FC<EnhancedLinkProps> = ({ href, method, ...props }) => {
  const finalHref = isRouteResult(href) ? href.url : href;
  const finalMethod = isRouteResult(href) && !method ? href.method : method;

  return (
    <InertiaLink
      href={finalHref}
      method={finalMethod}
      {...props}
    />
  );
};
```

**Vue Implementation (`Link.vue`):**
```vue
<script setup lang="ts">
import { computed } from 'vue';
import { Link as InertiaLink } from '@inertiajs/vue3';

export interface LinkProps {
  href: string | RouteResult;
  method?: Method;
  // ... other props
}

const props = defineProps<LinkProps>();

const finalHref = computed(() => {
  return isRouteResult(props.href) ? props.href.url : props.href;
});

const finalMethod = computed(() => {
  if (isRouteResult(props.href) && !props.method) {
    return props.href.method;
  }
  return props.method;
});
</script>

<template>
  <InertiaLink
    :href="finalHref"
    :method="finalMethod"
    v-bind="$attrs"
  >
    <slot />
  </InertiaLink>
</template>
```

**Key Differences:**
1. **File Type**: React uses `.tsx`, Vue uses `.vue` (Single File Component)
2. **Props Definition**:
   - React: Type extends `InertiaLinkProps`
   - Vue: Custom `LinkProps` interface with all props explicitly defined
3. **Computed Values**:
   - React: Direct inline computation in JSX
   - Vue: Uses `computed()` for reactive transformations
4. **Template Syntax**:
   - React: JSX with `{...props}`
   - Vue: Template with `:href`, `:method`, and `v-bind="$attrs"`
5. **Children**:
   - React: `{children}` prop
   - Vue: `<slot />` element

### 3. useForm Hook/Composable

**React Implementation:**
```typescript
import { useForm as useInertiaForm } from '@inertiajs/react';

export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route?: RouteResult
): BoundFormType<TForm> | UnboundFormType<TForm> {
  const inertiaForm = useInertiaForm<TForm>(data);

  if (!route || !isRouteResult(route)) {
    return inertiaForm;
  }

  const boundForm: BoundFormType<TForm> = {
    ...inertiaForm,
    submit(options?: BoundSubmitOptions) {
      return inertiaForm.submit(route.method, route.url, options);
    },
  };

  return boundForm as any;
}
```

**Vue Implementation:**
```typescript
import { useForm as useInertiaForm } from '@inertiajs/vue3';

export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route?: RouteResult
): BoundFormType<TForm> | UnboundFormType<TForm> {
  const inertiaForm = useInertiaForm<TForm>(data);

  if (!route || !isRouteResult(route)) {
    return inertiaForm;
  }

  const boundForm: BoundFormType<TForm> = {
    ...inertiaForm,
    submit(options?: BoundSubmitOptions) {
      return inertiaForm.submit(route.method as Method, route.url, options);
    },
  };

  return boundForm as any;
}
```

**Key Differences:**
1. **Import Source**: `@inertiajs/react` vs `@inertiajs/vue3`
2. **Type Casting**: Vue explicitly casts `route.method as Method`
3. **Data Access**:
   - React: `form.data` (property)
   - Vue: `form.data()` (function) - but this is in Inertia, not our wrapper
4. **Return Types**: Slightly different InertiaForm types between frameworks

### 4. Testing

**React Tests:**
- Uses `@testing-library/react`
- `renderHook` for hook testing
- `render` for component testing
- `@testing-library/jest-dom` matchers

**Vue Tests:**
- Uses `@vue/test-utils`
- Direct composable invocation for testing
- `mount` for component testing
- No special jest-dom matchers needed

**Test Coverage:**
Both implementations have identical test coverage:
- ✓ 62 tests total
- ✓ Router: 16 tests
- ✓ Link: 15 tests
- ✓ useForm: 31 tests

## Type Safety

Both implementations provide full TypeScript support:

### Shared Types
```typescript
export type RouteResult = {
  url: string;
  method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};
```

### React-Specific Types
```typescript
export type EnhancedLinkProps = Omit<InertiaLinkProps, 'href'> & {
  href: string | RouteResult;
};

export type BoundFormType<TForm> =
  Omit<ReturnType<typeof useInertiaForm<TForm>>, 'submit'> & {
    submit(options?: BoundSubmitOptions): void;
  };
```

### Vue-Specific Types
```typescript
export interface LinkProps {
  href: string | RouteResult;
  method?: Method;
  // ... explicitly defined props
}

export interface BoundFormType<TForm> extends Omit<InertiaForm<TForm>, 'submit'> {
  submit(options?: VisitOptions): void;
}
```

## Usage Comparison

### Router Usage

**React:**
```tsx
import { router } from '@/lib/inertia';
import { post_path } from '@/routes';

router.visit(post_path(1));
```

**Vue:**
```vue
<script setup>
import { router } from '@/lib/inertia';
import { post_path } from '@/routes';

router.visit(post_path(1));
</script>
```

*Identical usage - no framework-specific differences.*

### Link Usage

**React:**
```tsx
import { Link } from '@/lib/inertia';
import { post_path } from '@/routes';

function MyComponent() {
  return <Link href={post_path(1)}>View Post</Link>;
}
```

**Vue:**
```vue
<script setup>
import { Link } from '@/lib/inertia';
import { post_path } from '@/routes';
</script>

<template>
  <Link :href="post_path(1)">View Post</Link>
</template>
```

*Different template syntax but same concept.*

### useForm Usage

**React:**
```tsx
import { useForm } from '@/lib/inertia';
import { update_post_path } from '@/routes';

function EditPost() {
  const form = useForm({ title: 'Post' }, update_post_path.patch(1));

  const handleSubmit = (e) => {
    e.preventDefault();
    form.submit({ preserveScroll: true });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={form.data.title}
        onChange={(e) => form.setData('title', e.target.value)}
      />
      <button disabled={form.processing}>Save</button>
    </form>
  );
}
```

**Vue:**
```vue
<script setup>
import { useForm } from '@/lib/inertia';
import { update_post_path } from '@/routes';

const form = useForm({ title: 'Post' }, update_post_path.patch(1));

const handleSubmit = () => {
  form.submit({ preserveScroll: true });
};
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input v-model="form.title" type="text" />
    <button :disabled="form.processing">Save</button>
  </form>
</template>
```

*Different syntax but equivalent functionality.*

## Installer Integration

Both frameworks generate the same `lib/inertia.ts` pattern:

**React:**
```typescript
export { router } from '@nordbeam/nb-inertia/react/router';
export { Link } from '@nordbeam/nb-inertia/react/Link';
export { useForm } from '@nordbeam/nb-inertia/react/useForm';
export * from '@inertiajs/react';
```

**Vue:**
```typescript
export { router } from '@nordbeam/nb-inertia/vue/router';
export { default as Link } from '@nordbeam/nb-inertia/vue/Link.vue';
export { useForm } from '@nordbeam/nb-inertia/vue/useForm';
export * from '@inertiajs/vue3';
```

*Note: Vue uses `default as Link` because `.vue` files export default.*

## Summary

| Aspect | React | Vue | Notes |
|--------|-------|-----|-------|
| Router | `.tsx` file | `.ts` file | Identical logic |
| Link | TSX component | `.vue` SFC | Different component model |
| useForm | React hook | Composable | Nearly identical |
| Testing | RTL | VTU | Framework-specific |
| Type Safety | Full TS | Full TS | Both complete |
| API Surface | Identical | Identical | Same user experience |
| Test Coverage | 62 tests | 62 tests | Equivalent coverage |

The implementations are remarkably similar in structure and functionality, with differences primarily reflecting framework-specific patterns rather than design decisions. This ensures a consistent developer experience across both React and Vue while respecting each framework's idioms.
