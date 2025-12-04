import { default as React } from 'react';
import { RouteResult } from '../../shared/types';
import { ModalConfig } from './types';
/**
 * Props for the ModalLink component
 */
export interface ModalLinkProps extends Omit<React.AnchorHTMLAttributes<HTMLAnchorElement>, 'href'> {
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
    loadingComponent?: React.ComponentType;
    /**
     * Callback when the link is clicked
     */
    onClick?: (e: React.MouseEvent<HTMLAnchorElement>) => void;
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
    children?: React.ReactNode;
}
export declare const ModalLink: React.FC<ModalLinkProps>;
export default ModalLink;
//# sourceMappingURL=ModalLink.d.ts.map