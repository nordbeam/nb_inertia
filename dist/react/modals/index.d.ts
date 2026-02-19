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
export { ModalStackProvider, useModalStack, useModal, useIsInModal, useModalPageContext, ModalPageProvider, } from './modalStack';
export type { ModalPageObject, ModalPageProviderProps, ModalStackProviderProps, ResolveComponentFn, } from './modalStack';
export { usePage } from './usePage';
export type { Page } from './usePage';
export { InitialModalHandler } from './InitialModalHandler';
export type { InitialModalHandlerProps, ModalOnBase } from './InitialModalHandler';
export { ClientModalLink } from './ClientModalLink';
export type { ClientModalLinkProps } from './ClientModalLink';
export { ModalLink } from './ModalLink';
export type { ModalLinkProps } from './ModalLink';
export { HeadlessModal } from './HeadlessModal';
export type { HeadlessModalProps } from './HeadlessModal';
export { ModalRenderer } from './ModalRenderer';
export type { ModalRendererProps, ModalRenderContext } from './ModalRenderer';
export { CloseButton } from './CloseButton';
export type { CloseButtonProps } from './CloseButton';
export type { ModalConfig, ModalSize, ModalPosition, ModalInstance, ModalStackContextValue, PrefetchedModal, TypedModalProps, TypedModalInstance, } from './types';
export { DEFAULT_MODAL_CONFIG, mergeModalConfig } from './types';
export { setupModalInterceptor, isModalInterceptorRegistered } from '../preserveBackdrop';
//# sourceMappingURL=index.d.ts.map