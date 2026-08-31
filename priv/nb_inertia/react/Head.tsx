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

import React, { Component, createElement, useMemo } from 'react';
import { Head as InertiaHead } from '@inertiajs/react';
import { createPortal } from 'react-dom';
import { useIsInModal } from './modals/modalStack';

/**
 * Props for the Head component (matches Inertia's HeadProps)
 */
export type HeadProps = React.ComponentProps<typeof InertiaHead>;

type ModalHeadFallbackProps = HeadProps;

function hasTitleElement(children: React.ReactNode): boolean {
  return React.Children.toArray(children).some((child) => {
    if (!React.isValidElement(child)) {
      return false;
    }

    if (child.type === React.Fragment) {
      return hasTitleElement((child.props as { children?: React.ReactNode }).children);
    }

    return child.type === 'title';
  });
}

function addInertiaMarkers(children: React.ReactNode): React.ReactNode[] {
  const nodes: React.ReactNode[] = [];

  React.Children.forEach(children, (child) => {
    if (!React.isValidElement(child)) {
      if (child) {
        nodes.push(child);
      }
      return;
    }

    if (child.type === React.Fragment) {
      nodes.push(...addInertiaMarkers((child.props as { children?: React.ReactNode }).children));
      return;
    }

    const props = child.props as Record<string, unknown>;
    const headKey = props['head-key'];
    const inertiaKey =
      typeof headKey === 'string' || typeof headKey === 'number' ? String(headKey) : '';

    nodes.push(
      React.cloneElement(child as React.ReactElement<Record<string, unknown>>, {
        'data-inertia': inertiaKey,
      }),
    );
  });

  return nodes;
}

/**
 * Standalone fallback for custom modal renderers mounted outside Inertia's
 * private HeadContext. Native head children are portaled into document.head,
 * which keeps modal title/meta/link/script elements live and removable.
 */
function ModalHeadFallback({ title, children }: ModalHeadFallbackProps) {
  const headChildren = useMemo(() => {
    const nodes = addInertiaMarkers(children);

    if (title && !hasTitleElement(children)) {
      nodes.push(createElement('title', { 'data-inertia': '' }, title));
    }

    return nodes;
  }, [children, title]);

  if (typeof document === 'undefined') {
    return null;
  }

  return createPortal(headChildren, document.head);
}

interface ModalHeadBoundaryProps {
  children: React.ReactNode;
  fallback: React.ReactNode;
}

interface ModalHeadBoundaryState {
  hasError: boolean;
}

class ModalHeadBoundary extends Component<ModalHeadBoundaryProps, ModalHeadBoundaryState> {
  state: ModalHeadBoundaryState = { hasError: false };

  static getDerivedStateFromError(): ModalHeadBoundaryState {
    return { hasError: true };
  }

  render() {
    return this.state.hasError ? this.props.fallback : this.props.children;
  }
}

/**
 * Enhanced Head component
 *
 * Delegate to Inertia's head manager in every context. Modal content is
 * rendered below the application's Inertia provider, so using the official
 * component preserves title callbacks, server-head handling, head keys, and
 * child elements such as meta/link/script tags.
 *
 * @param props - Head props (title and optional children)
 */
export const Head: React.FC<HeadProps> = (props) => {
  const isInModal = useIsInModal();

  if (!isInModal) {
    return <InertiaHead {...props} />;
  }

  return (
    <ModalHeadBoundary fallback={<ModalHeadFallback {...props} />}>
      <InertiaHead {...props} />
    </ModalHeadBoundary>
  );
};

export default Head;
