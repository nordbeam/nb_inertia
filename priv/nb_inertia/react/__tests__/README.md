# NbInertia React Component Integration Tests

This directory contains comprehensive integration tests for the enhanced NbInertia React components that provide seamless integration with nb_routes rich mode.

## Test Files

### `Link.test.tsx`
Tests for the enhanced Link component that accepts both RouteResult objects and plain string URLs.

**Test Coverage:**
- ✅ Renders correct href from RouteResult
- ✅ Renders correct method from RouteResult
- ✅ Handles all HTTP methods (GET, POST, PATCH, PUT, DELETE, HEAD)
- ✅ Explicit method prop overrides RouteResult method
- ✅ Backward compatibility with plain string URLs
- ✅ Passes through all Inertia Link props (className, data, preserveState, etc.)
- ✅ Edge cases (empty strings, query params, hash fragments, absolute URLs)
- ✅ Type guard validation for invalid RouteResult objects
- ✅ Children rendering

### `router.test.tsx`
Tests for the enhanced router that wraps Inertia's router with RouteResult support.

**Test Coverage:**
- ✅ `visit()` extracts URL and method from RouteResult
- ✅ `visit()` preserves explicit method in options over RouteResult
- ✅ `visit()` passes through all visit options
- ✅ All HTTP method helpers: `get()`, `post()`, `put()`, `patch()`, `delete()`
- ✅ Backward compatibility with plain string URLs
- ✅ Data handling in POST/PUT/PATCH requests
- ✅ Callback options (onBefore, onStart, onProgress, onSuccess, onError, onCancel, onFinish)
- ✅ Edge cases (empty strings, query params, hash fragments, absolute URLs)
- ✅ Complex data objects
- ✅ Preserves all Inertia router properties

### `useForm.test.tsx`
Tests for the enhanced useForm hook with optional route binding.

**Test Coverage:**
- ✅ Bound forms: `submit()` uses route's URL and method without arguments
- ✅ Bound forms: `submit(options)` accepts visit options
- ✅ Works with all HTTP methods (GET, POST, PATCH, PUT, DELETE)
- ✅ Unbound forms: standard Inertia `submit(method, url, options)` signature
- ✅ Preserves all form properties (data, setData, transform, reset, clearErrors, errors, processing, etc.)
- ✅ Passes through all visit options and callbacks
- ✅ Form data management (complex nested data, files)
- ✅ Form state management (errors, processing, progress, wasSuccessful, etc.)
- ✅ Real-world patterns (create, edit, delete, file upload)
- ✅ Edge cases (empty data, query params, hash fragments, absolute URLs)
- ✅ Type guard validation

## Running Tests

### Install Dependencies
```bash
cd /Users/assim/Projects/nb/nb_inertia/priv/nb_inertia/react
npm install
```

### Run All Tests
```bash
npm test
```

### Watch Mode (for development)
```bash
npm run test:watch
```

### Coverage Report
```bash
npm run test:coverage
```

### Interactive UI
```bash
npm run test:ui
```

## Test Stack

- **Vitest**: Fast, Vite-native test runner with excellent TypeScript support
- **@testing-library/react**: Modern React testing utilities focused on user behavior
- **jsdom**: DOM implementation for Node.js testing
- **@testing-library/jest-dom**: Custom matchers for DOM assertions

## Test Philosophy

These tests focus on **integration testing** rather than unit testing:

1. **Mock @inertiajs/react**: We mock the Inertia components/hooks to verify our wrappers call them correctly
2. **Test behavior, not implementation**: Tests verify the components work correctly from a user's perspective
3. **Comprehensive edge cases**: Tests cover normal usage, edge cases, and error conditions
4. **Type safety**: Tests verify TypeScript types work correctly
5. **Backward compatibility**: Every test suite includes backward compatibility tests with plain strings

## Key Testing Patterns

### Mocking Inertia
```typescript
vi.mock('@inertiajs/react', () => ({
  Link: vi.fn(({ href, method, children, ...props }) => (
    <a href={href} data-method={method} {...props}>{children}</a>
  )),
}));
```

### Testing RouteResult Objects
```typescript
const route: RouteResult = {
  url: '/posts/1',
  method: 'patch',
};

render(<Link href={route}>Edit Post</Link>);
expect(link).toHaveAttribute('href', '/posts/1');
expect(link).toHaveAttribute('data-method', 'patch');
```

### Testing Backward Compatibility
```typescript
// Should still work with plain strings
render(<Link href="/posts/1">View Post</Link>);
expect(link).toHaveAttribute('href', '/posts/1');
```

## Adding New Tests

When adding new features to the React components:

1. Add tests to the appropriate test file
2. Follow the existing test structure (describe blocks for feature groups)
3. Test both happy path and edge cases
4. Include backward compatibility tests
5. Verify type safety with TypeScript
6. Run `npm run test:coverage` to ensure good coverage

## CI/CD Integration

These tests can be integrated into the CI/CD pipeline:

```bash
# In CI environment
npm ci
npm test
```

For coverage requirements, use:
```bash
npm run test:coverage -- --coverage.thresholds.lines=80
```

## Troubleshooting

### Tests fail with "Cannot find module '@inertiajs/react'"
Run `npm install` to install dependencies.

### Tests fail with TypeScript errors
Make sure `tsconfig.json` is properly configured and run `npm install` to get the latest type definitions.

### Mock not working as expected
Verify the mock is defined before the component import. Vitest hoists `vi.mock()` calls automatically.

## Related Documentation

- [Link Component](../Link.tsx)
- [Router](../router.tsx)
- [useForm Hook](../useForm.tsx)
- [Vitest Documentation](https://vitest.dev/)
- [Testing Library Documentation](https://testing-library.com/docs/react-testing-library/intro/)
