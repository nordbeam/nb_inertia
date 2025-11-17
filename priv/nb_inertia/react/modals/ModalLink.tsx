/**
 * NbInertia ModalLink Component for React
 *
 * Provides a link component that opens Inertia pages in modals instead of
 * navigating to them. When clicked, it fetches the target page and displays
 * it in a modal overlay.
 *
 * @example
 * import { ModalLink } from '@/modals/ModalLink';
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
 */

import React, { useState, useCallback } from 'react';
import { router } from '../router';
import { type RouteResult } from '../router';
import { useModalStack, type ModalConfig } from './HeadlessModal';

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
 * Type guard to check if a value is a RouteResult object
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
export const ModalLink: React.FC<ModalLinkProps> = ({
  href,
  method,
  data,
  modalConfig = {},
  baseUrl,
  onClick,
  children,
  className,
  ...anchorProps
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const { pushModal } = useModalStack();

  // Extract URL and method from RouteResult if provided
  const finalHref = isRouteResult(href) ? href.url : href;
  const finalMethod = (isRouteResult(href) && !method ? href.method : method) || 'get';

  const handleClick = useCallback((e: React.MouseEvent<HTMLAnchorElement>) => {
    // Allow modifier keys to work normally (open in new tab, etc.)
    if (e.ctrlKey || e.metaKey || e.shiftKey) {
      return;
    }

    e.preventDefault();

    // Call user's onClick if provided
    if (onClick) {
      onClick(e);
    }

    setIsLoading(true);

    // Use Inertia router to fetch the modal page
    // The response will contain modal headers if it's a modal response
    router.visit(finalHref, {
      method: finalMethod,
      data,
      preserveState: true,
      preserveScroll: true,
      only: [], // Don't merge with current page props
      onSuccess: (page) => {
        // The page response should contain modal information
        // For now, we assume the component name from the page response
        // In a full implementation, the backend would send modal headers

        // Extract modal data from response (this is a simplified version)
        // In practice, you'd read custom headers from the response
        const component = page.component;
        const props = page.props;

        // Push modal to stack
        pushModal({
          component: component as any, // This would need proper component resolution
          props,
          config: modalConfig,
          baseUrl: baseUrl || window.location.pathname,
        });

        setIsLoading(false);
      },
      onError: () => {
        setIsLoading(false);
      },
      onFinish: () => {
        setIsLoading(false);
      },
    });
  }, [finalHref, finalMethod, data, modalConfig, baseUrl, onClick, pushModal]);

  // Build the class names
  const linkClassName = [
    className,
    isLoading ? 'opacity-50 cursor-wait' : 'cursor-pointer',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <a
      href={finalHref}
      className={linkClassName}
      onClick={handleClick}
      {...anchorProps}
    >
      {children}
    </a>
  );
};

export default ModalLink;
