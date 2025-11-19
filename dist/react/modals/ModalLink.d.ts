import { default as React } from 'react';
import { RouteResult } from '../router';
import { ModalConfig } from './HeadlessModal';
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
    onClick?: (e: React.MouseEvent<HTMLAnchorElement>) => void;
    /**
     * Children to render
     */
    children?: React.ReactNode;
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
export declare const ModalLink: React.FC<ModalLinkProps>;
export default ModalLink;
//# sourceMappingURL=ModalLink.d.ts.map