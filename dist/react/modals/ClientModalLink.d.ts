import { ModalConfig } from './types';
import { RouteResult } from '../../shared/types';
/**
 * Props for ClientModalLink
 */
export interface ClientModalLinkProps {
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
 * SSR-safe modal link component
 *
 * Renders a regular Inertia Link during SSR and hydration,
 * then switches to ModalLink on the client after mount.
 * This prevents SSR errors from useModalStack context.
 */
export declare function ClientModalLink({ href, children, className, modalConfig, loadingComponent, prefetch, cacheFor, cacheTags, }: ClientModalLinkProps): import("react/jsx-runtime").JSX.Element;
export default ClientModalLink;
//# sourceMappingURL=ClientModalLink.d.ts.map