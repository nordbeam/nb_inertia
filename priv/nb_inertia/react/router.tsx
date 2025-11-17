/**
 * NbInertia Enhanced Router for React
 *
 * Provides enhanced Inertia.js router that accepts both string URLs and RouteResult objects
 * from nb_routes rich mode. Maintains full backward compatibility with standard Inertia usage.
 *
 * @example
 * import { router } from '@/nb_inertia/router';
 * import { post_path, update_post_path } from '@/routes';
 *
 * // Use with RouteResult objects
 * router.visit(post_path(1));                    // Automatically uses GET
 * router.visit(update_post_path.patch(1));       // Automatically uses PATCH
 *
 * // Still works with plain strings
 * router.visit('/posts/1');
 * router.get('/posts/1');
 */

import { router as inertiaRouter, type VisitOptions } from '@inertiajs/react';

/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing the router to automatically use the correct HTTP method.
 */
export type RouteResult = {
  url: string;
  method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
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

/**
 * Normalize a URL or RouteResult to a string URL
 *
 * @param urlOrRoute - String URL or RouteResult object
 * @returns The URL string
 */
function normalizeUrl(urlOrRoute: string | RouteResult): string {
  return isRouteResult(urlOrRoute) ? urlOrRoute.url : urlOrRoute;
}

/**
 * Extract the HTTP method from a RouteResult or use a default
 *
 * @param urlOrRoute - String URL or RouteResult object
 * @param defaultMethod - Method to use if urlOrRoute is a string
 * @returns The HTTP method
 */
function extractMethod(
  urlOrRoute: string | RouteResult,
  defaultMethod: RouteResult['method']
): RouteResult['method'] {
  return isRouteResult(urlOrRoute) ? urlOrRoute.method : defaultMethod;
}

/**
 * Enhanced Inertia router that accepts RouteResult objects
 *
 * Wraps the standard Inertia.js router with enhanced methods that can accept
 * RouteResult objects from nb_routes rich mode, while maintaining full backward
 * compatibility with string URLs.
 *
 * Uses Object.create to properly inherit prototype methods like .on()
 */
export const router = Object.assign(Object.create(inertiaRouter), {
  ...inertiaRouter,

  /**
   * Visit a URL with automatic method detection
   *
   * When given a RouteResult, automatically uses the method from the route.
   * When given a string, uses the method from options or defaults to 'get'.
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options
   *
   * @example
   * // With RouteResult (method auto-detected)
   * router.visit(post_path(1));                    // Uses GET
   * router.visit(update_post_path.patch(1));       // Uses PATCH
   *
   * // With string (backward compatible)
   * router.visit('/posts/1');
   * router.visit('/posts/1', { method: 'post' });
   */
  visit(urlOrRoute: string | RouteResult, options: VisitOptions = {}) {
    const url = normalizeUrl(urlOrRoute);

    // If urlOrRoute is a RouteResult and no explicit method in options,
    // use the method from the RouteResult
    const finalOptions: VisitOptions = isRouteResult(urlOrRoute) && !options.method
      ? { ...options, method: urlOrRoute.method }
      : options;

    return inertiaRouter.visit(url, finalOptions);
  },

  /**
   * Make a GET request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options (method will be overridden to 'get')
   *
   * @example
   * router.get(post_path(1));
   * router.get('/posts/1');
   */
  get(urlOrRoute: string | RouteResult, options: VisitOptions = {}) {
    const url = normalizeUrl(urlOrRoute);
    return inertiaRouter.get(url, options);
  },

  /**
   * Make a POST request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'post')
   *
   * @example
   * router.post(posts_path(), { title: 'New Post' });
   * router.post('/posts', { title: 'New Post' });
   */
  post(
    urlOrRoute: string | RouteResult,
    data: Record<string, unknown> = {},
    options: VisitOptions = {}
  ) {
    const url = normalizeUrl(urlOrRoute);
    return inertiaRouter.post(url, data, options);
  },

  /**
   * Make a PUT request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'put')
   *
   * @example
   * router.put(update_post_path.put(1), { title: 'Updated' });
   * router.put('/posts/1', { title: 'Updated' });
   */
  put(
    urlOrRoute: string | RouteResult,
    data: Record<string, unknown> = {},
    options: VisitOptions = {}
  ) {
    const url = normalizeUrl(urlOrRoute);
    return inertiaRouter.put(url, data, options);
  },

  /**
   * Make a PATCH request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'patch')
   *
   * @example
   * router.patch(update_post_path.patch(1), { title: 'Updated' });
   * router.patch('/posts/1', { title: 'Updated' });
   */
  patch(
    urlOrRoute: string | RouteResult,
    data: Record<string, unknown> = {},
    options: VisitOptions = {}
  ) {
    const url = normalizeUrl(urlOrRoute);
    return inertiaRouter.patch(url, data, options);
  },

  /**
   * Make a DELETE request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options (method will be overridden to 'delete')
   *
   * @example
   * router.delete(delete_post_path.delete(1));
   * router.delete('/posts/1');
   */
  delete(urlOrRoute: string | RouteResult, options: VisitOptions = {}) {
    const url = normalizeUrl(urlOrRoute);
    return inertiaRouter.delete(url, options);
  },
});

export default router;
