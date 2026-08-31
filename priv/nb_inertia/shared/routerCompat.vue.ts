/**
 * Router compatibility utilities for Vue (imports from @inertiajs/vue3)
 *
 * @see routerCompat.ts for the React version
 */

import type { PrefetchOptions, UrlMethodPair, VisitOptions } from '@inertiajs/core';
import { router } from '@inertiajs/vue3';

/**
 * Call router.prefetch with typed parameters.
 *
 * @param url - URL to prefetch
 * @param visitOptions - Inertia visit options (e.g. { preserveState: true })
 * @param prefetchOptions - Prefetch-specific options (e.g. { cacheFor: 30000 })
 */
export function routerPrefetch(
  url: string | URL | UrlMethodPair,
  visitOptions?: VisitOptions,
  prefetchOptions?: Partial<PrefetchOptions>,
): void {
  router.prefetch(url, visitOptions, prefetchOptions);
}
