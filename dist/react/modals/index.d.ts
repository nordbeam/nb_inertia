/**
 * NbInertia Modal System - Public API
 *
 * This module provides a complete modal and slideover system for Inertia.js applications
 * built on Radix UI Dialog primitives. It includes:
 *
 * - Modal stack management with support for nested modals
 * - Event system for modal lifecycle hooks
 * - Styled modal and slideover components
 * - Integration with nb_routes for type-safe navigation
 * - Full TypeScript support
 *
 * @example Basic usage
 * ```tsx
 * import { ModalStackProvider, Modal } from '@/modals';
 *
 * function App() {
 *   return (
 *     <ModalStackProvider>
 *       <YourApp />
 *     </ModalStackProvider>
 *   );
 * }
 *
 * function UserProfile() {
 *   return (
 *     <Modal
 *       component={UserProfileContent}
 *       componentProps={{ userId: 1 }}
 *       baseUrl="/users"
 *       config={{ size: 'lg' }}
 *     >
 *       {(close) => <button onClick={close}>Close</button>}
 *     </Modal>
 *   );
 * }
 * ```
 *
 * @example With ModalLink
 * ```tsx
 * import { ModalLink } from '@/modals';
 * import { user_path } from '@/routes';
 *
 * function UsersList() {
 *   return (
 *     <ModalLink href={user_path(1)} modalConfig={{ size: 'lg' }}>
 *       View User
 *     </ModalLink>
 *   );
 * }
 * ```
 */
export { ModalStackProvider, useModalStack, useModal, } from './modalStack';
export { Modal } from './Modal';
export { HeadlessModal } from './HeadlessModal';
export { ModalLink } from './ModalLink';
export { ModalContent } from './ModalContent';
export { SlideoverContent } from './SlideoverContent';
export { CloseButton } from './CloseButton';
export type { ModalConfig, ModalSize, ModalPosition, ModalEventType, ModalEventHandler, ModalInstance, ModalStackContextValue, } from './types';
export { DEFAULT_MODAL_CONFIG, mergeModalConfig, } from './types';
export type { ModalProps } from './Modal';
export type { HeadlessModalProps } from './HeadlessModal';
export type { ModalLinkProps } from './ModalLink';
export type { ModalContentProps } from './ModalContent';
export type { SlideoverContentProps } from './SlideoverContent';
export type { CloseButtonProps } from './CloseButton';
//# sourceMappingURL=index.d.ts.map