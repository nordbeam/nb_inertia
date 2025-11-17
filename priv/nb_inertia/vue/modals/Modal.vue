<template>
  <HeadlessModal
    :component="component"
    :component-props="componentProps"
    :config="config"
    :base-url="baseUrl"
    :open="open"
    @close="emit('close')"
  >
    <template #default="{ modal, close }">
      <DialogRoot :open="open" @update:open="(val) => !val && close()">
        <DialogPortal>
          <!-- Backdrop/Overlay -->
          <DialogOverlay :class="backdropClasses" :style="{ zIndex: getZIndex(modal.index) }" />

          <!-- Modal or Slideover Content -->
          <SlideoverContent
            v-if="isSlideover"
            :config="config"
            :class="className"
            :z-index="getZIndex(modal.index) + 1"
          >
            <!-- Close Button -->
            <CloseButton v-if="showCloseButton" @close="close" />

            <!-- Content -->
            <slot :close="close">
              <component :is="component" v-bind="componentProps" :close="close" />
            </slot>
          </SlideoverContent>

          <ModalContent
            v-else
            :config="config"
            :class="className"
            :z-index="getZIndex(modal.index) + 1"
          >
            <!-- Close Button -->
            <CloseButton v-if="showCloseButton" @close="close" />

            <!-- Content -->
            <slot :close="close">
              <component :is="component" v-bind="componentProps" :close="close" />
            </slot>
          </ModalContent>
        </DialogPortal>
      </DialogRoot>
    </template>
  </HeadlessModal>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { DialogRoot, DialogPortal, DialogOverlay } from 'radix-vue';
import HeadlessModal from './HeadlessModal.vue';
import ModalContent from './ModalContent.vue';
import SlideoverContent from './SlideoverContent.vue';
import CloseButton from './CloseButton.vue';
import type { ModalConfig } from './types';
import type { Component } from 'vue';

/**
 * Modal - Styled modal component using Radix Vue Dialog
 *
 * This component wraps HeadlessModal with a styled UI layer using Radix Vue Dialog primitives.
 * It supports:
 * - Configurable size and position
 * - Modal and slideover variants
 * - Stacked modals with proper z-indexing
 * - Custom styling through className and config
 * - Close button (optional)
 * - Backdrop rendering
 *
 * @example Basic modal
 * ```vue
 * <template>
 *   <Modal
 *     :component="UserForm"
 *     :component-props="{ userId: 1 }"
 *     base-url="/users"
 *     :config="{ size: 'lg', position: 'center', closeButton: true }"
 *   >
 *     <template #default="{ close }">
 *       <h2>User Form</h2>
 *       <UserFormContent />
 *       <button @click="close">Close</button>
 *     </template>
 *   </Modal>
 * </template>
 * ```
 *
 * @example Slideover variant
 * ```vue
 * <template>
 *   <Modal
 *     :component="UserEdit"
 *     :component-props="{ user }"
 *     base-url="/users"
 *     :config="{ slideover: true, position: 'right', size: 'lg' }"
 *   >
 *     <template #default="{ close }">
 *       <EditUserForm @close="close" />
 *     </template>
 *   </Modal>
 * </template>
 * ```
 */

interface Props {
  /**
   * Modal component to render
   */
  component: Component;

  /**
   * Props to pass to the modal component
   */
  componentProps?: Record<string, any>;

  /**
   * Modal configuration
   */
  config?: ModalConfig;

  /**
   * Base URL for the modal (used for navigation)
   */
  baseUrl: string;

  /**
   * Whether the modal is currently open
   */
  open?: boolean;

  /**
   * Custom class names for styling
   */
  className?: string;
}

const props = withDefaults(defineProps<Props>(), {
  componentProps: () => ({}),
  config: () => ({}),
  open: true,
});

const emit = defineEmits<{
  (e: 'close'): void;
}>();

const isSlideover = computed(() => props.config?.slideover || false);
const showCloseButton = computed(() => props.config?.closeButton !== false);

const backdropClasses = computed(() => {
  const defaults = 'fixed inset-0 bg-black/50';
  return props.config?.backdropClasses ? `${defaults} ${props.config.backdropClasses}` : defaults;
});

/**
 * Get z-index based on modal stack index
 */
function getZIndex(index: number): number {
  const baseZIndex = 50;
  return baseZIndex + index;
}
</script>
