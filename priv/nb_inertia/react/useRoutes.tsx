/**
 * useRoutes Hook for Auto-Scoped Route Helpers
 *
 * Automatically injects a scope parameter (e.g., account subdomain) into route helpers,
 * eliminating the need for manual prop drilling throughout your application.
 *
 * @example
 * import { useRoutes } from '@nordbeam/nb-inertia/react/useRoutes';
 * import * as rawRoutes from './routes';
 *
 * function MyComponent() {
 *   const routes = useRoutes(rawRoutes, {
 *     scopeParam: 'account_subdomain',
 *     getScopeValue: (props) => props.currentScope?.account?.subdomain,
 *   });
 *
 *   // Subdomain automatically injected!
 *   router.visit(routes.spaces_index_path());
 *   router.visit(routes.space_path(space.id));
 * }
 */

import { usePage } from '@inertiajs/react';
import { useMemo } from 'react';

export interface UseRoutesOptions<TPageProps = Record<string, unknown>> {
  /**
   * Name of the parameter to auto-inject (e.g., 'account_subdomain', 'tenant_id')
   */
  scopeParam: string;

  /**
   * Function to extract the scope value from Inertia page props
   * Receives the page props and should return the value to inject
   *
   * @example
   * getScopeValue: (props) => props.currentScope?.account?.subdomain
   */
  getScopeValue: (props: TPageProps) => string | number | undefined;

  /**
   * Whether to throw an error if the scope value is not available
   * @default true
   */
  throwOnMissing?: boolean;
}

type RouteFunction = (...args: any[]) => any;
type RouteHelpers = Record<string, RouteFunction>;

/**
 * Wrap a single route function to auto-inject the scope parameter
 * Returns a properly typed function that preserves the original return type
 */
function wrapRouteFunction(
  fn: RouteFunction,
  scopeValue: string | number
): RouteFunction {
  // Create the wrapped function that injects scope value
  const wrapped: RouteFunction = (...args: any[]) => {
    return fn(scopeValue, ...args);
  };

  // Copy all properties and method variants from the original function
  // This preserves .get(), .post(), .patch(), .url(), .form, etc.
  Object.keys(fn).forEach((key) => {
    const value = (fn as any)[key];
    if (typeof value === 'function') {
      // Wrap method variants to also inject scope value
      (wrapped as any)[key] = (...args: any[]) => {
        return value(scopeValue, ...args);
      };
    } else if (typeof value === 'object' && value !== null) {
      // Handle nested objects like .form
      const wrappedNested: any = {};
      Object.keys(value).forEach((nestedKey) => {
        const nestedValue = value[nestedKey];
        if (typeof nestedValue === 'function') {
          wrappedNested[nestedKey] = (...args: any[]) => {
            return nestedValue(scopeValue, ...args);
          };
        } else {
          wrappedNested[nestedKey] = nestedValue;
        }
      });
      (wrapped as any)[key] = wrappedNested;
    } else {
      // Copy non-function properties
      (wrapped as any)[key] = value;
    }
  });

  // Preserve function metadata
  Object.defineProperty(wrapped, 'name', {
    value: fn.name,
    writable: false,
  });

  return wrapped;
}

/**
 * React hook that provides auto-scoped route helpers
 *
 * Automatically injects a scope parameter from Inertia page props as the first
 * parameter to all route helpers, eliminating the need to manually pass it
 * throughout your application.
 *
 * @param routeHelpers - Object containing route helper functions
 * @param options - Configuration for scope parameter injection
 * @returns Route helpers with scope parameter removed from signatures
 *
 * @throws {Error} If scope value is not available and throwOnMissing is true
 *
 * @example
 * // Setup in your app
 * import { useRoutes } from '@nordbeam/nb-inertia/react/useRoutes';
 * import * as rawRoutes from './routes';
 *
 * function MyComponent() {
 *   const routes = useRoutes(rawRoutes, {
 *     scopeParam: 'account_subdomain',
 *     getScopeValue: (props) => props.currentScope?.account?.subdomain,
 *   });
 *
 *   // Before (manual scope passing)
 *   // router.visit(rawRoutes.spaces_index_path(account.subdomain));
 *   // router.visit(rawRoutes.space_path(account.subdomain, space.id));
 *
 *   // After (auto-scoped)
 *   router.visit(routes.spaces_index_path());
 *   router.visit(routes.space_path(space.id));
 * }
 */
export function useRoutes<
  TRouteHelpers extends RouteHelpers = RouteHelpers,
  TPageProps = Record<string, unknown>
>(
  routeHelpers: TRouteHelpers,
  options: UseRoutesOptions<TPageProps>
): TRouteHelpers {
  const { props } = usePage<TPageProps>();
  const { scopeParam, getScopeValue, throwOnMissing = true } = options;

  // Extract the scope value from page props
  const scopeValue = getScopeValue(props);

  // Validate that we have a scope value
  if (scopeValue === undefined || scopeValue === null) {
    if (throwOnMissing) {
      throw new Error(
        `[useRoutes] Scope parameter "${scopeParam}" is not available in page props. ` +
          `Make sure the value returned by getScopeValue() is defined.`
      );
    }
    // If not throwing, return the original helpers unchanged
    return routeHelpers;
  }

  // Memoize the wrapped routes to avoid recreating on every render
  return useMemo(() => {
    const wrappedRoutes: any = {};

    Object.keys(routeHelpers).forEach((key) => {
      const routeFn = routeHelpers[key];
      if (typeof routeFn === 'function') {
        wrappedRoutes[key] = wrapRouteFunction(routeFn, scopeValue);
      } else {
        // Non-function properties (shouldn't happen, but handle gracefully)
        wrappedRoutes[key] = routeFn;
      }
    });

    return wrappedRoutes as TRouteHelpers;
  }, [routeHelpers, scopeValue]);
}

export default useRoutes;
