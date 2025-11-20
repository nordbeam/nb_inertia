import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines all available configuration options for modals and slideovers.
 * All fields are optional with sensible defaults.
 */
declare interface ModalConfig {
    /**
     * Size of the modal
     * @default 'md'
     *
     * Presets: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full'
     * Custom: Any valid CSS class string (e.g., 'max-w-4xl')
     */
    size?: ModalSize;
    /**
     * Position of the modal on screen
     * @default 'center'
     *
     * Presets: 'center' | 'top' | 'bottom' | 'left' | 'right'
     * Custom: Any valid CSS class string
     */
    position?: ModalPosition;
    /**
     * Whether this is a slideover (slides in from side) instead of a modal
     * @default false
     */
    slideover?: boolean;
    /**
     * Show a close button in the top-right corner
     * @default true
     */
    closeButton?: boolean;
    /**
     * Require explicit close (disables ESC key and backdrop click)
     * @default false
     */
    closeExplicitly?: boolean;
    /**
     * Custom max-width CSS value
     * @example '800px', '50rem'
     */
    maxWidth?: string;
    /**
     * Custom padding classes for modal content
     * @default 'p-6'
     * @example 'p-8', 'px-4 py-6'
     */
    paddingClasses?: string;
    /**
     * Custom panel classes for the modal container
     * @default 'bg-white rounded-lg shadow-xl'
     * @example 'bg-gray-900 text-white rounded-xl'
     */
    panelClasses?: string;
    /**
     * Custom backdrop classes for the overlay
     * @default 'bg-black/50'
     * @example 'bg-gray-900/75', 'backdrop-blur-sm'
     */
    backdropClasses?: string;
}

/**
 * ModalLink - Link component that opens pages in modals
 *
 * When clicked, this component fetches the target page and displays it in a modal
 * instead of navigating to it. The modal integrates with the modal stack and
 * supports all modal configuration options.
 *
 * Features:
 * - Accepts both string URLs and RouteResult objects
 * - Shows loading state during fetch
 * - Configurable modal appearance via modalConfig
 * - Prevents default navigation behavior
 * - Maintains browser history integration
 *
 * @example
 * ```tsx
 * import { ModalLink } from '@/modals/ModalLink';
 * import { user_path, edit_user_path } from '@/routes';
 *
 * // Basic usage
 * <ModalLink href={user_path(1)}>View User</ModalLink>
 *
 * // With RouteResult
 * <ModalLink href={edit_user_path(1)}>Edit User</ModalLink>
 *
 * // With custom modal config
 * <ModalLink
 *   href={user_path(1)}
 *   modalConfig={{
 *     size: 'lg',
 *     position: 'center',
 *     closeButton: true
 *   }}
 * >
 *   View Details
 * </ModalLink>
 *
 * // Slideover variant
 * <ModalLink
 *   href={edit_user_path(1)}
 *   modalConfig={{
 *     slideover: true,
 *     position: 'right'
 *   }}
 * >
 *   Edit
 * </ModalLink>
 * ```
 */
declare const ModalLink: default_2.FC<ModalLinkProps>;
export { ModalLink }
export default ModalLink;

/**
 * Props for the ModalLink component
 */
export declare interface ModalLinkProps extends Omit<default_2.AnchorHTMLAttributes<HTMLAnchorElement>, 'href'> {
    /**
     * The URL or RouteResult to navigate to
     *
     * Can be a plain string URL or a RouteResult object from nb_routes rich mode.
     */
    href: string | RouteResult;
    /**
     * Optional modal configuration
     *
     * Configure the modal appearance and behavior when opened.
     */
    modalConfig?: ModalConfig;
    /**
     * Base URL for the modal
     *
     * When the modal closes, the browser will navigate to this URL.
     * If not provided, uses the current URL.
     */
    baseUrl?: string;
    /**
     * HTTP method to use for the request
     *
     * Defaults to 'get'. Can be overridden if href is a string.
     * When href is a RouteResult, the method from the route is used unless explicitly overridden.
     */
    method?: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
    /**
     * Data to send with the request (for POST/PUT/PATCH/DELETE)
     */
    data?: Record<string, any>;
    /**
     * Callback when the link is clicked
     */
    onClick?: (e: default_2.MouseEvent<HTMLAnchorElement>) => void;
    /**
     * Children to render
     */
    children?: default_2.ReactNode;
}

/**
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

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
declare type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head' | 'options';
};

export { }
