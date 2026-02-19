/**
 * Router compatibility utilities for working with Inertia's internal APIs.
 *
 * Inertia's router.prefetch is not part of the public TypeScript API but is
 * available at runtime in Inertia v2. This module provides feature-detected
 * access to avoid `as any` casts throughout the codebase.
 */
/**
 * Safely call router.prefetch if available.
 *
 * Inertia v2 exposes prefetch on the router but it's not in the public
 * TypeScript types. This function does a runtime feature check before calling.
 *
 * @param url - URL to prefetch
 * @param visitOptions - Inertia visit options (e.g. { preserveState: true })
 * @param prefetchOptions - Prefetch-specific options (e.g. { cacheFor: 30000 })
 * @returns true if prefetch was called, false if not available
 */
export declare function routerPrefetch(url: string, visitOptions?: Record<string, unknown>, prefetchOptions?: Record<string, unknown>): boolean;
//# sourceMappingURL=routerCompat.d.ts.map