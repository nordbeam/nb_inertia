import { default as React } from 'react';
import { InertiaLinkProps } from '@inertiajs/react';
import { RouteResult } from './router';
/**
 * Enhanced Link props that accept RouteResult objects
 *
 * Extends the standard Inertia Link props to accept RouteResult objects
 * in the href prop, while maintaining backward compatibility with strings.
 * Also includes standard HTML anchor attributes for full compatibility.
 */
export type EnhancedLinkProps = Omit<InertiaLinkProps, 'href'> & Omit<React.AnchorHTMLAttributes<HTMLAnchorElement>, 'href'> & {
    /**
     * The URL or RouteResult to navigate to
     *
     * Can be a plain string URL or a RouteResult object from nb_routes rich mode.
     * When a RouteResult is provided, the URL and method are automatically extracted.
     *
     * @example
     * // String URL
     * <Link href="/posts/1">View</Link>
     *
     * // RouteResult object
     * <Link href={post_path(1)}>View</Link>
     * <Link href={update_post_path.patch(1)}>Edit</Link>
     */
    href: string | RouteResult;
};
/**
 * Enhanced Link component that accepts RouteResult objects
 *
 * Wraps the standard Inertia.js Link component with enhanced functionality that
 * can accept RouteResult objects from nb_routes rich mode, while maintaining
 * full backward compatibility with string URLs.
 *
 * Features:
 * - Accepts both string URLs and RouteResult objects in href prop
 * - Automatically extracts URL and method from RouteResult objects
 * - Passes all other props through to Inertia Link unchanged
 * - Full TypeScript support with proper prop types
 * - Maintains all Inertia Link functionality (preserveState, preserveScroll, etc.)
 *
 * @param props - Enhanced Link props
 *
 * @example
 * import { Link } from '@/nb_inertia/Link';
 * import { post_path, update_post_path, delete_post_path } from '@/routes';
 *
 * // Basic usage with RouteResult
 * <Link href={post_path(1)}>View Post</Link>
 *
 * // With method from RouteResult
 * <Link href={update_post_path.patch(1)}>Edit Post</Link>
 * <Link href={delete_post_path.delete(1)} as="button">Delete</Link>
 *
 * // Still works with plain strings
 * <Link href="/posts/1">View Post</Link>
 * <Link href="/posts" method="post">Create Post</Link>
 *
 * // With additional Inertia options
 * <Link
 *   href={post_path(1)}
 *   preserveState
 *   preserveScroll
 *   only={['post']}
 * >
 *   View Post
 * </Link>
 *
 * // With data for POST/PATCH/PUT/DELETE
 * <Link
 *   href={update_post_path.patch(1)}
 *   data={{ title: 'Updated Title' }}
 *   preserveScroll
 * >
 *   Update Title
 * </Link>
 */
export declare function Link({ href, method, ...props }: EnhancedLinkProps): import("react/jsx-runtime").JSX.Element;
export default Link;
//# sourceMappingURL=Link.d.ts.map