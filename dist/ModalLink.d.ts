import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines behavioral configuration options for modals.
 * Styling is left to the user's UI implementation.
 * All fields are optional with sensible defaults.
 */
declare interface ModalConfig {
    /**
     * Size hint for the modal
     * @default 'md'
     *
     * Presets: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full'
     * Your UI implementation can interpret this however you like.
     */
    size?: ModalSize;
    /**
     * Position hint for the modal
     * @default 'center'
     *
     * Presets: 'center' | 'top' | 'bottom' | 'left' | 'right'
     * Your UI implementation can interpret this however you like.
     */
    position?: ModalPosition;
    /**
     * Whether this is a slideover (slides in from side) instead of a centered modal
     * @default false
     */
    slideover?: boolean;
    /**
     * Whether to show a close button
     * @default true
     */
    closeButton?: boolean;
    /**
     * Require explicit close (disables ESC key and backdrop click)
     * @default false
     */
    closeExplicitly?: boolean;
    /**
     * Any additional custom data your UI implementation needs
     * This is passed through to your modal renderer unchanged.
     */
    [key: string]: unknown;
}

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
     * Note: This is passed to the backend via query params if needed,
     * but typically the backend controls modal configuration.
     */
    modalConfig?: ModalConfig;
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
     * Custom loading component to display while modal content is loading
     *
     * If provided, this component will be rendered in the modal shell
     * while waiting for the server response. If not provided, a default
     * loading spinner will be shown.
     *
     * @example
     * ```tsx
     * <ModalLink
     *   href={edit_user_path(1)}
     *   loadingComponent={UserFormSkeleton}
     * >
     *   Edit User
     * </ModalLink>
     * ```
     */
    loadingComponent?: default_2.ComponentType;
    /**
     * Callback when the link is clicked
     */
    onClick?: (e: default_2.MouseEvent<HTMLAnchorElement>) => void;
    /**
     * Enable prefetching. Can be:
     * - boolean: true enables hover prefetch
     * - 'hover' | 'mount' | 'click': single mode
     * - ('hover' | 'mount' | 'click')[]: multiple modes
     *
     * Note: Prefetching only works for GET requests.
     *
     * @example
     * ```tsx
     * // Prefetch on hover
     * <ModalLink href={user_path(1)} prefetch>View User</ModalLink>
     *
     * // Prefetch on mount
     * <ModalLink href={user_path(1)} prefetch="mount">View User</ModalLink>
     *
     * // Multiple modes
     * <ModalLink href={user_path(1)} prefetch={['hover', 'mount']}>View User</ModalLink>
     * ```
     */
    prefetch?: boolean | 'hover' | 'mount' | 'click' | ('hover' | 'mount' | 'click')[];
    /**
     * Duration in milliseconds to cache prefetched data
     *
     * @default 30000 (30 seconds)
     */
    cacheFor?: number;
    /**
     * Tags for organizing cached prefetch data
     *
     * Can be used to invalidate specific cached prefetch data.
     */
    cacheTags?: string[];
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
 * Shared types and utilities for nb_inertia
 *
 * This module provides common types and utilities used across React and Vue components.
 */
/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing components to automatically use the correct HTTP method.
 *
 * NOTE: This type matches @inertiajs/core's UrlMethodPair type exactly.
 * The official Inertia.js router and Link components already support this pattern.
 */
declare type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete';
};

export { }
