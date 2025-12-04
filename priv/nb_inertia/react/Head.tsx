/**
 * Enhanced Head component for nb_inertia
 *
 * This component extends Inertia's Head to work correctly inside modals.
 * When rendered inside a modal context, it updates the document title directly
 * instead of using Inertia's head manager (which requires PageContext).
 *
 * @example
 * ```tsx
 * // Import from @/lib/inertia (which re-exports from nb_inertia)
 * import { Head } from '@/lib/inertia';
 *
 * function MyPage() {
 *   // Works in both normal pages AND inside modals
 *   return (
 *     <>
 *       <Head title="My Page" />
 *       <div>Content</div>
 *     </>
 *   );
 * }
 * ```
 */

import React, { useEffect, useRef } from 'react';
import { Head as InertiaHead } from '@inertiajs/react';
import { useIsInModal, useModalPageContext } from './modals/modalStack';

/**
 * Props for the Head component (matches Inertia's HeadProps)
 */
export interface HeadProps {
  title?: string;
  children?: React.ReactNode;
}

/**
 * Enhanced Head component
 *
 * Checks if we're inside a modal context. If so, handles document title
 * updates directly. Otherwise, delegates to Inertia's Head component.
 *
 * In modal context:
 * - Only the `title` prop is supported
 * - The original title is restored when the modal closes
 * - Child elements (meta tags, etc.) are ignored in modal context
 *
 * @param props - Head props (title and optional children)
 */
export const Head: React.FC<HeadProps> = ({ title, children }) => {
  const isInModal = useIsInModal();
  const originalTitleRef = useRef<string | null>(null);

  // Handle modal context - update document.title directly
  useEffect(() => {
    if (!isInModal || !title) return;

    // Save original title on mount
    if (originalTitleRef.current === null) {
      originalTitleRef.current = document.title;
    }

    // Update document title
    document.title = title;

    // Restore original title on unmount
    return () => {
      if (originalTitleRef.current !== null) {
        document.title = originalTitleRef.current;
      }
    };
  }, [isInModal, title]);

  // If in modal, we've handled the title above - render nothing
  if (isInModal) {
    return null;
  }

  // Not in modal - delegate to Inertia's Head
  return <InertiaHead title={title}>{children}</InertiaHead>;
};

export default Head;
