/**
 * NbInertia ModalLink Component for React
 *
 * Provides a link component that opens Inertia pages in modals instead of
 * navigating to them.
 *
 * @example
 * ```tsx
 * import { ModalLink } from '@nordbeam/nb-inertia/modals';
 * import { user_path } from '@/routes';
 *
 * // Open user show page in a modal
 * <ModalLink href={user_path(1)}>View User</ModalLink>
 *
 * // With custom modal configuration
 * <ModalLink
 *   href={user_path(1)}
 *   modalConfig={{ size: 'lg', position: 'center' }}
 * >
 *   View User Details
 * </ModalLink>
 * ```
 */

import React, { useCallback, useMemo, useEffect, useRef } from 'react';
import { router } from '@inertiajs/react';
import { isRouteResult, type RouteResult } from '../../shared/types';
import { routerPrefetch } from '../../shared/routerCompat';
import type { ModalConfig } from './types';
import { useModalStack } from './modalStack';
import type { ResolveComponentFn } from './modalStack';

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

/**
 * ModalLink - Link component that opens pages in modals
 *
 * When clicked, this component:
 * 1. Triggers an Inertia visit to fetch the content
 * 2. InitialModalHandler renders the modal when response arrives
 *
 * Features:
 * - Accepts both string URLs and RouteResult objects
 * - Prevents default navigation behavior
 * - Respects modifier keys (Ctrl/Cmd+click opens in new tab)
 *
 * @example
 * ```tsx
 * import { ModalLink } from '@nordbeam/nb-inertia/modals';
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
 *   modalConfig={{ size: 'lg', position: 'center' }}
 * >
 *   View Details
 * </ModalLink>
 * ```
 */
/**
 * Placeholder component for loading modals
 * This is used as the component when the modal is in loading state
 */
const LoadingPlaceholder: React.FC = () => null;

export const ModalLink: React.FC<ModalLinkProps> = ({
  href,
  method,
  data,
  modalConfig,
  loadingComponent,
  onClick,
  prefetch,
  cacheFor,
  cacheTags,
  children,
  className,
  ...anchorProps
}) => {
  const { pushModal, modals, prefetchModal, getPrefetchedModal } = useModalStack();

  // Extract URL and method from RouteResult if provided
  const finalHref = isRouteResult(href) ? href.url : href;
  const finalMethod = (isRouteResult(href) && !method ? href.method : method) || 'get';

  // Normalize prefetch prop to array of modes
  const prefetchModes = useMemo(() => {
    if (!prefetch) return [];
    if (prefetch === true) return ['hover'] as const;
    if (typeof prefetch === 'string') return [prefetch] as const;
    return prefetch;
  }, [prefetch]);

  // Prefetch function - uses our custom prefetch that loads both data AND component
  const doPrefetch = useCallback(() => {
    if (finalMethod !== 'get') return;

    // Use our custom prefetchModal if available (loads data + component)
    if (prefetchModal) {
      prefetchModal(finalHref, { cacheFor });
    } else {
      // Fallback to Inertia's prefetch (data only)
      const prefetchOptions: { cacheFor?: number; cacheTags?: string[] } = {};
      if (cacheFor !== undefined) prefetchOptions.cacheFor = cacheFor;
      if (cacheTags !== undefined) prefetchOptions.cacheTags = cacheTags;
      routerPrefetch(finalHref, { preserveState: true }, prefetchOptions);
    }
  }, [finalHref, finalMethod, cacheFor, cacheTags, prefetchModal]);

  // Mount prefetch
  useEffect(() => {
    if (prefetchModes.includes('mount')) {
      const timer = setTimeout(doPrefetch, 0);
      return () => clearTimeout(timer);
    }
  }, [prefetchModes, doPrefetch]);

  // Hover prefetch with delay
  const hoverTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handleMouseEnter = useCallback(
    (e: React.MouseEvent<HTMLAnchorElement>) => {
      // Call any existing onMouseEnter from anchorProps
      anchorProps.onMouseEnter?.(e);

      if (prefetchModes.includes('hover')) {
        hoverTimeoutRef.current = setTimeout(doPrefetch, 75);
      }
    },
    [prefetchModes, doPrefetch, anchorProps]
  );

  const handleMouseLeave = useCallback(
    (e: React.MouseEvent<HTMLAnchorElement>) => {
      // Call any existing onMouseLeave from anchorProps
      anchorProps.onMouseLeave?.(e);

      if (hoverTimeoutRef.current) {
        clearTimeout(hoverTimeoutRef.current);
        hoverTimeoutRef.current = null;
      }
    },
    [anchorProps]
  );

  // Click prefetch (mousedown)
  const handleMouseDown = useCallback(
    (e: React.MouseEvent<HTMLAnchorElement>) => {
      // Call any existing onMouseDown from anchorProps
      anchorProps.onMouseDown?.(e);

      if (prefetchModes.includes('click')) {
        doPrefetch();
      }
    },
    [prefetchModes, doPrefetch, anchorProps]
  );

  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLAnchorElement>) => {
      // Allow modifier keys to work normally (open in new tab, etc.)
      if (e.ctrlKey || e.metaKey || e.shiftKey) {
        return;
      }

      e.preventDefault();

      // Call user's onClick if provided
      if (onClick) {
        onClick(e);
      }

      // Check if there's already a modal for this URL (prevent duplicates)
      const existingModal = modals.find((m) => m.url === finalHref);
      if (existingModal) {
        return;
      }

      // Capture the current full URL (with query params) before opening the modal
      // This will be used to restore the URL when the modal closes
      const returnUrl = typeof window !== 'undefined' ? window.location.href : '';

      // Check if we have fully prefetched data (both data AND component)
      const prefetched = getPrefetchedModal?.(finalHref);
      if (prefetched) {
        // Instant modal opening - no loading state needed!
        pushModal({
          component: prefetched.component,
          componentName: prefetched.data.component,
          props: prefetched.data.props,
          url: prefetched.data.url,
          config: prefetched.data.config || modalConfig || {},
          baseUrl: prefetched.data.baseUrl,
          returnUrl,
          onClose: () => {
            // Update URL to the original URL (with query params) when modal is closed
            if (returnUrl && typeof window !== 'undefined') {
              window.history.replaceState({}, '', returnUrl);
            }
          },
        });

        // Update browser URL to modal URL
        if (typeof window !== 'undefined') {
          window.history.pushState({}, '', prefetched.data.url);
        }

        return;
      }

      // No prefetched data - show loading modal and fetch via Inertia
      pushModal({
        component: LoadingPlaceholder,
        componentName: '',
        props: {},
        url: finalHref,
        config: modalConfig || {},
        baseUrl: '', // Will be updated by InitialModalHandler
        returnUrl, // Capture the return URL now so it's available when modal is updated
        loading: true,
        loadingComponent,
      });

      // Fetch the content via Inertia
      // InitialModalHandler will update the loading modal when response arrives
      router.visit(finalHref, {
        method: finalMethod,
        data: data ?? {},
        preserveState: true,
        preserveScroll: true,
      });
    },
    [finalHref, finalMethod, data, onClick, modalConfig, loadingComponent, pushModal, modals, getPrefetchedModal]
  );

  return (
    <a
      href={finalHref}
      className={className}
      onClick={handleClick}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onMouseDown={handleMouseDown}
      {...anchorProps}
    >
      {children}
    </a>
  );
};

export default ModalLink;
