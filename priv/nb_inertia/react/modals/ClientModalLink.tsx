/**
 * ClientModalLink - SSR-safe wrapper for ModalLink
 *
 * During SSR, renders a regular Link. On the client, renders ModalLink.
 * This avoids the "useModalStack must be used within ModalStackProvider" error during SSR.
 *
 * @example
 * ```tsx
 * import { ClientModalLink } from '@nordbeam/nb-inertia/modals';
 * import { user_path } from '@/routes';
 *
 * // SSR-safe modal link
 * <ClientModalLink href={user_path(user.id)}>
 *   View User
 * </ClientModalLink>
 *
 * // With modal configuration
 * <ClientModalLink
 *   href={edit_user_path(user.id)}
 *   modalConfig={{ size: 'lg', slideover: true }}
 * >
 *   Edit User
 * </ClientModalLink>
 * ```
 */

import { useState, useEffect } from 'react';
import { Link } from '@inertiajs/react';
import { ModalLink } from './ModalLink';
import type { ModalConfig } from './types';
import type { RouteResult } from '../../shared/types';

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
export function ClientModalLink({
  href,
  children,
  className,
  modalConfig,
  loadingComponent,
  prefetch,
  cacheFor,
  cacheTags,
}: ClientModalLinkProps) {
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  // During SSR or before hydration, render a regular Link
  // Pass prefetch and cacheFor to Inertia Link for SSR prefetching
  if (!isMounted) {
    const url = typeof href === 'string' ? href : href.url;
    return (
      <Link
        href={url}
        className={className}
        prefetch={prefetch}
        cacheFor={cacheFor}
      >
        {children}
      </Link>
    );
  }

  // On client, render ModalLink with prefetch support
  return (
    <ModalLink
      href={href}
      className={className}
      modalConfig={modalConfig}
      loadingComponent={loadingComponent}
      prefetch={prefetch}
      cacheFor={cacheFor}
      cacheTags={cacheTags}
    >
      {children}
    </ModalLink>
  );
}

export default ClientModalLink;
