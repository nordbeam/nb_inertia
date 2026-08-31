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

import React, { Component, useEffect } from 'react';
import { Head as InertiaHead } from '@inertiajs/react';
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

const HEAD_ATTRIBUTE_NAMES: Record<string, string> = {
  charSet: 'charset',
  className: 'class',
  crossOrigin: 'crossorigin',
  httpEquiv: 'http-equiv',
  itemProp: 'itemprop',
  referrerPolicy: 'referrerpolicy',
};

function childText(children: React.ReactNode): string {
  return React.Children.toArray(children)
    .map((child) => {
      if (typeof child === 'string' || typeof child === 'number') {
        return String(child);
      }

      if (React.isValidElement(child)) {
        return childText((child.props as { children?: React.ReactNode }).children);
      }

      return '';
    })
    .join('');
}

function appendFallbackHeadNodes(
  children: React.ReactNode,
  title: string | undefined,
): HTMLElement[] {
  const nodes: HTMLElement[] = [];
  let childTitle: string | undefined;

  const appendChildren = (headChildren: React.ReactNode) => {
    React.Children.forEach(headChildren, (child) => {
      if (!React.isValidElement(child)) return;

      if (child.type === React.Fragment) {
        appendChildren((child.props as { children?: React.ReactNode }).children);
        return;
      }

      if (typeof child.type !== 'string') return;

      const props = child.props as Record<string, unknown>;
      if (child.type === 'title') {
        childTitle = childText(props.children as React.ReactNode);
        return;
      }

      const element = document.createElement(child.type);
      const headKey = props['head-key'];
      element.setAttribute(
        'data-nb-inertia-modal-head',
        typeof headKey === 'string' || typeof headKey === 'number' ? String(headKey) : '',
      );

      Object.entries(props).forEach(([name, value]) => {
        if (['children', 'dangerouslySetInnerHTML', 'head-key'].includes(name)) return;
        if (
          value === false ||
          value === null ||
          value === undefined ||
          (typeof value !== 'string' && typeof value !== 'number' && typeof value !== 'boolean')
        ) {
          return;
        }

        element.setAttribute(
          HEAD_ATTRIBUTE_NAMES[name] ?? name,
          value === true ? '' : String(value),
        );
      });

      const html = props.dangerouslySetInnerHTML as { __html?: string } | undefined;
      if (html?.__html !== undefined) {
        element.innerHTML = html.__html;
      } else if (props.children !== undefined) {
        element.textContent = childText(props.children as React.ReactNode);
      }

      document.head.appendChild(element);
      nodes.push(element);
    });
  };

  appendChildren(children);

  const resolvedTitle = childTitle || title;
  if (resolvedTitle) {
    const titleElement = document.createElement('title');
    titleElement.setAttribute('data-nb-inertia-modal-head', '');
    titleElement.textContent = resolvedTitle;
    document.head.insertBefore(titleElement, document.head.querySelector('title'));
    nodes.push(titleElement);
  }

  return nodes;
}

/**
 * Standalone fallback for custom modal renderers mounted outside Inertia's
 * private HeadContext. The nodes are owned imperatively because React 19
 * hoists head elements while Inertia also reconciles document.head. Allowing
 * both systems to own a modal title can make React remove an element that
 * Inertia already detached during navigation.
 */
function ModalHeadFallback({ title, children }: ModalHeadFallbackProps) {
  useEffect(() => {
    if (typeof document === 'undefined') return;

    const nodes = appendFallbackHeadNodes(children, hasTitleElement(children) ? undefined : title);

    return () => {
      nodes.forEach((node) => {
        if (node.parentNode === document.head) {
          document.head.removeChild(node);
        }
      });
    };
  }, [children, title]);

  return null;
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
