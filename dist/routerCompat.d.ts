/**
 * Router compatibility utilities.
 *
 * In Inertia v3, router.prefetch is a first-class public API with full
 * TypeScript types. This module provides a thin wrapper for consistent usage.
 */
/**
 * Call router.prefetch with typed parameters.
 *
 * @param url - URL to prefetch
 * @param visitOptions - Inertia visit options (e.g. { preserveState: true })
 * @param prefetchOptions - Prefetch-specific options (e.g. { cacheFor: 30000 })
 */
export declare function routerPrefetch(url: string, visitOptions?: Record<string, unknown>, prefetchOptions?: Record<string, unknown>): void;

export { }
