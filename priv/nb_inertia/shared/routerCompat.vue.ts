/**
 * Router compatibility utilities for Vue (imports from @inertiajs/vue3)
 *
 * @see routerCompat.ts for the React version
 */

import { router } from '@inertiajs/vue3';

/**
 * Call router.prefetch with typed parameters.
 *
 * @param url - URL to prefetch
 * @param visitOptions - Inertia visit options (e.g. { preserveState: true })
 * @param prefetchOptions - Prefetch-specific options (e.g. { cacheFor: 30000 })
 */
export function routerPrefetch(
  url: string,
  visitOptions?: Record<string, unknown>,
  prefetchOptions?: Record<string, unknown>
): void {
  (router as any).prefetch(url, visitOptions, prefetchOptions);
}
