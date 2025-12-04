/**
 * NbInertia Modal System - Hook-First API
 *
 * This module provides a hook-first modal system for Inertia.js applications.
 * It handles the hard parts (state management, history integration, prop handling)
 * while you bring your own UI (Radix, shadcn, Headless UI, etc.).
 *
 * @example Basic setup with your own UI
 * ```tsx
 * import {
 *   ModalStackProvider,
 *   useModalStack,
 *   InitialModalHandler,
 * } from '@nordbeam/nb-inertia/modals';
 * import { Dialog } from '@radix-ui/react-dialog';
 *
 * // Set up component resolver (using Vite's import.meta.glob)
 * const pages = import.meta.glob('./pages/**\/*.tsx');
 * const resolveComponent = (name: string) =>
 *   pages[`./pages/${name}.tsx`]().then((m: any) => m.default);
 *
 * function App({ Component, props }) {
 *   return (
 *     <ModalStackProvider>
 *       <Component {...props} />
 *       <InitialModalHandler resolveComponent={resolveComponent} />
 *       <MyModalRenderer resolveComponent={resolveComponent} />
 *     </ModalStackProvider>
 *   );
 * }
 *
 * // Your custom modal renderer using any UI library
 * function MyModalRenderer({ resolveComponent }) {
 *   const { modals, popModal } = useModalStack();
 *
 *   return modals.map((modal) => (
 *     <Dialog key={modal.id} open onOpenChange={() => popModal(modal.id)}>
 *       <ModalPageProvider props={modal.props}>
 *         <modal.component {...modal.props} />
 *       </ModalPageProvider>
 *     </Dialog>
 *   ));
 * }
 * ```
 *
 * @example Using ModalLink with your UI
 * ```tsx
 * import { ModalLink } from '@nordbeam/nb-inertia/modals';
 * import { user_path } from '@/routes';
 *
 * // ModalLink triggers the fetch, your renderer handles the display
 * <ModalLink href={user_path(1)}>View User</ModalLink>
 * ```
 */

// Core modal stack management (hooks and context)
export {
  ModalStackProvider,
  useModalStack,
  useModal,
  // Modal page context utilities
  useIsInModal,
  useModalPageContext,
  ModalPageProvider,
} from './modalStack';

export type {
  ModalPageObject,
  ModalPageProviderProps,
  ModalStackProviderProps,
  ResolveComponentFn,
} from './modalStack';

// Enhanced usePage hook that works in modals
export { usePage } from './usePage';
export type { Page } from './usePage';

// Integration component - handles _nb_modal prop and navigation events
export { InitialModalHandler } from './InitialModalHandler';
export type { InitialModalHandlerProps, ModalOnBase } from './InitialModalHandler';

// SSR-safe modal link wrapper
export { ClientModalLink } from './ClientModalLink';
export type { ClientModalLinkProps } from './ClientModalLink';

// Link component that triggers modal fetches
export { ModalLink } from './ModalLink';
export type { ModalLinkProps } from './ModalLink';

// Types and configuration
export type {
  ModalConfig,
  ModalSize,
  ModalPosition,
  ModalInstance,
  ModalStackContextValue,
  PrefetchedModal,
} from './types';

export { DEFAULT_MODAL_CONFIG, mergeModalConfig } from './types';

// Modal backdrop preservation (axios interceptor)
export { setupModalInterceptor, isModalInterceptorRegistered } from '../preserveBackdrop';
