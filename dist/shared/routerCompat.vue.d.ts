import { PrefetchOptions, UrlMethodPair, VisitOptions } from '@inertiajs/core';
/**
 * Call router.prefetch with typed parameters.
 *
 * @param url - URL to prefetch
 * @param visitOptions - Inertia visit options (e.g. { preserveState: true })
 * @param prefetchOptions - Prefetch-specific options (e.g. { cacheFor: 30000 })
 */
export declare function routerPrefetch(url: string | URL | UrlMethodPair, visitOptions?: VisitOptions, prefetchOptions?: Partial<PrefetchOptions>): void;
//# sourceMappingURL=routerCompat.vue.d.ts.map