/**
 * Enhanced usePage hook for nb_inertia
 *
 * This hook extends Inertia's usePage to work correctly inside modals.
 * When called inside a modal context, it returns the modal's page object
 * instead of throwing an error.
 *
 * @example
 * ```tsx
 * // Import from @/lib/inertia (which re-exports from nb_inertia)
 * import { usePage } from '@/lib/inertia';
 *
 * function MyComponent() {
 *   // Works in both normal pages AND inside modals
 *   const { props } = usePage<MyPageProps>();
 *   return <div>{props.user.name}</div>;
 * }
 * ```
 */

import type { Page as InertiaPage, PageProps, SharedPageProps } from '@inertiajs/core';
import { usePage as inertiaUsePage } from '@inertiajs/react';
import { useModalPageContext } from './modals/modalStack';

/**
 * Page object structure (matches Inertia's Page type)
 */
export type Page<TProps extends PageProps = PageProps> = Omit<
  InertiaPage<TProps & SharedPageProps>,
  'version'
> & {
  version: string | number | null;
  scrollRegions?: Array<{ top: number; left: number }>;
};

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
export function usePage<TProps extends PageProps = PageProps>(): Page<TProps> {
  // First, check if we're in a modal context
  const modalPage = useModalPageContext();

  if (modalPage) {
    // We're inside a modal - return the modal's page object
    return {
      component: modalPage.component,
      props: modalPage.props as TProps & SharedPageProps,
      url: modalPage.url,
      version: modalPage.version || null,
      flash: modalPage.flash || {},
      scrollRegions: modalPage.scrollRegions || [],
      rememberedState: modalPage.rememberedState || {},
      clearHistory: modalPage.clearHistory,
      encryptHistory: modalPage.encryptHistory,
      preserveFragment: modalPage.preserveFragment,
    } as Page<TProps>;
  }

  // Not in a modal - delegate to Inertia's usePage
  // This will throw if also not inside Inertia's App component
  return inertiaUsePage<TProps>() as Page<TProps>;
}

export default usePage;
