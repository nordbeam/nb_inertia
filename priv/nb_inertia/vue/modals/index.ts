/**
 * NbInertia Modal System - Public API (Vue)
 *
 * This module provides a complete modal and slideover system for Inertia.js Vue applications
 * built on Radix Vue Dialog primitives. It includes:
 *
 * - Modal stack management with support for nested modals
 * - Event system for modal lifecycle hooks
 * - Styled modal and slideover components
 * - Integration with nb_routes for type-safe navigation
 * - Full TypeScript support
 *
 * @example Basic usage
 * ```vue
 * <template>
 *   <div>
 *     <Modal
 *       :component="UserProfileContent"
 *       :component-props="{ userId: 1 }"
 *       base-url="/users"
 *       :config="{ size: 'lg' }"
 *     >
 *       <template #default="{ close }">
 *         <button @click="close">Close</button>
 *       </template>
 *     </Modal>
 *   </div>
 * </template>
 *
 * <script setup>
 * import { provide } from 'vue';
 * import { createModalStack, MODAL_STACK_KEY, Modal } from '@/modals';
 *
 * // In your root component
 * const modalStack = createModalStack();
 * provide(MODAL_STACK_KEY, modalStack);
 * </script>
 * ```
 *
 * @example With ModalLink
 * ```vue
 * <template>
 *   <ModalLink :href="user_path(1)" :modal-config="{ size: 'lg' }">
 *     View User
 *   </ModalLink>
 * </template>
 *
 * <script setup>
 * import { ModalLink } from '@/modals';
 * import { user_path } from '@/routes';
 * </script>
 * ```
 */

// Core modal stack management
export {
  createModalStack,
  useModalStack,
  useModal,
  MODAL_STACK_KEY,
} from './modalStack';

// Modal components
export { default as Modal } from './Modal.vue';
export { default as HeadlessModal } from './HeadlessModal.vue';
export { default as ModalLink } from './ModalLink.vue';

// Content components
export { default as ModalContent } from './ModalContent.vue';
export { default as SlideoverContent } from './SlideoverContent.vue';
export { default as CloseButton } from './CloseButton.vue';

// Types and configuration
export type {
  ModalConfig,
  ModalSize,
  ModalPosition,
  ModalEventType,
  ModalEventHandler,
  ModalInstance,
  ModalStackState,
} from './types';

export {
  DEFAULT_MODAL_CONFIG,
  mergeModalConfig,
} from './types';
