import { JSX } from 'react/jsx-runtime';

/**
 * SSR-safe modal link component
 *
 * Renders a regular Inertia Link during SSR and hydration,
 * then switches to ModalLink on the client after mount.
 * This prevents SSR errors from useModalStack context.
 */
declare function ClientModalLink({ href, children, className, modalConfig, loadingComponent, prefetch, cacheFor, cacheTags, }: ClientModalLinkProps): JSX.Element;
export { ClientModalLink }
export default ClientModalLink;

/**
 * Props for ClientModalLink
 */
export declare interface ClientModalLinkProps {
    /**
     * The URL or RouteResult to navigate to
     */
    href: string | RouteResult;
    /**
     * Content to render inside the link
     */
    children: React.ReactNode;
    /**
     * CSS class name(s) for the link
     */
    className?: string;
    /**
     * Modal configuration when opening as modal
     */
    modalConfig?: ModalConfig;
    /**
     * Custom loading component to display while modal content is loading
     *
     * If provided, this component will be rendered in the modal shell
     * while waiting for the server response. If not provided, a default
     * loading spinner will be shown.
     */
    loadingComponent?: React.ComponentType;
    /**
     * Enable prefetching. Can be:
     * - boolean: true enables hover prefetch
     * - 'hover' | 'mount' | 'click': single mode
     * - ('hover' | 'mount' | 'click')[]: multiple modes
     *
     * Note: Prefetching only works for GET requests.
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
     */
    cacheTags?: string[];
}

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

/**
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

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
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};

export { }
