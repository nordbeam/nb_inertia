/**
 * Enhanced usePage hook for nb_inertia modals
 *
 * This hook extends Inertia's usePage to work correctly inside modals.
 * When called inside a modal context, it returns the modal's page object
 * instead of the backdrop page's props.
 *
 * IMPORTANT: Import this from '@nordbeam/nb-inertia/react/modals' to ensure
 * it uses the same context as the modal components.
 *
 * @example
 * ```tsx
 * // Import from @/lib/inertia (which re-exports from nb_inertia/modals)
 * import { usePage } from '@/lib/inertia';
 *
 * function MyComponent() {
 *   // Works in both normal pages AND inside modals
 *   const { props } = usePage<MyPageProps>();
 *   return <div>{props.user.name}</div>;
 * }
 * ```
 */

import { usePage as inertiaUsePage } from '@inertiajs/react';
import { useModalPageContext } from './modalStack';

/**
 * Page object structure (matches Inertia's Page type)
 */
export interface Page<TProps = Record<string, any>> {
  component: string;
  props: TProps;
  url: string;
  version: string | null;
  scrollRegions: Array<{ top: number; left: number }>;
  rememberedState: Record<string, unknown>;
  clearHistory: boolean;
  encryptHistory: boolean;
}

/**
 * Enhanced usePage hook
 *
 * Checks if we're inside a modal context first. If so, returns the modal's
 * page object. Otherwise, delegates to Inertia's usePage.
 *
 * This allows components to use usePage() seamlessly whether they're rendered
 * as a full page or inside a modal.
 *
 * @returns The current page object with props
 */
export function usePage<TProps = Record<string, any>>(): Page<TProps> {
  // First, check if we're in a modal context
  const modalPage = useModalPageContext();

  if (modalPage) {
    // We're inside a modal - return the modal's page object
    return {
      component: modalPage.component,
      props: modalPage.props as TProps,
      url: modalPage.url,
      version: modalPage.version || null,
      scrollRegions: modalPage.scrollRegions || [],
      rememberedState: modalPage.rememberedState || {},
      clearHistory: modalPage.clearHistory || false,
      encryptHistory: modalPage.encryptHistory || false,
    };
  }

  // Not in a modal - delegate to Inertia's usePage
  // This will throw if also not inside Inertia's App component
  return inertiaUsePage<TProps>();
}

export default usePage;
