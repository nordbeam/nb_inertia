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
/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing the router to automatically use the correct HTTP method.
 */
export type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head' | 'options';
};
/**
 * Enhanced Inertia router that accepts RouteResult objects
 *
 * Wraps the standard Inertia.js router with enhanced methods that can accept
 * RouteResult objects from nb_routes rich mode, while maintaining full backward
 * compatibility with string URLs.
 *
 * Uses Object.create to properly inherit prototype methods like .on()
 */
export declare const router: any;
export default router;
//# sourceMappingURL=router.d.ts.map