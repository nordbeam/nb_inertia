/**
 * Router compatibility utilities for Vue (imports from @inertiajs/vue3)
 *
 * @see routerCompat.ts for the React version
 */

import { router } from '@inertiajs/vue3';

/**
 * Safely call router.prefetch if available.
 *
 * @see routerCompat.ts for full documentation
 */
export function routerPrefetch(
  url: string,
  visitOptions?: Record<string, unknown>,
  prefetchOptions?: Record<string, unknown>
): boolean {
  const r = router as Record<string, unknown>;
  if (typeof r.prefetch === 'function') {
    r.prefetch(url, visitOptions, prefetchOptions);
    return true;
  }
  return false;
}
