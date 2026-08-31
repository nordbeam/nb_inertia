/**
 * ClientModalLink - SSR-safe wrapper for ModalLink
 *
 * During SSR, renders a regular Link. On the client, renders ModalLink.
 * This avoids the "useModalStack must be used within ModalStackProvider" error during SSR.
 *
 * @example
 * ```tsx
 * import { ClientModalLink } from '@nordbeam/nb-inertia/react/modals';
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
import { ModalLink, type ModalLinkProps } from './ModalLink';

/**
 * Props for ClientModalLink
 */
export type ClientModalLinkProps = Omit<ModalLinkProps, 'children'> & {
  children: React.ReactNode;
};

/**
 * SSR-safe modal link component
 *
 * Renders a regular Inertia Link during SSR and hydration,
 * then switches to ModalLink on the client after mount.
 * This prevents SSR errors from useModalStack context.
 */
export function ClientModalLink({ children, ...modalLinkProps }: ClientModalLinkProps) {
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  // During SSR or before hydration, render a regular Link
  if (!isMounted) {
    const {
      modalConfig: _modalConfig,
      loadingComponent: _loadingComponent,
      returnUrl: _returnUrl,
      ...inertiaLinkProps
    } = modalLinkProps;

    return <Link {...(inertiaLinkProps as React.ComponentProps<typeof Link>)}>{children}</Link>;
  }

  // On client, render ModalLink with prefetch support
  return <ModalLink {...modalLinkProps}>{children}</ModalLink>;
}

export default ClientModalLink;
