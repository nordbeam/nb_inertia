<template>
  <slot v-if="isOpen && modalId" :modal="currentModal" :close="close" />
</template>

<script setup lang="ts">
import { ref, watch, onUnmounted, computed } from 'vue';
import { router } from '../router';
import { useModalStack } from './modalStack';
import type { ModalConfig } from './types';
import type { Component } from 'vue';

/**
 * HeadlessModal - Core modal state management for Vue
 *
 * Provides foundational modal logic without any UI:
 * - Modal stack integration
 * - Event system (close, success, blur, focus, beforeClose)
 * - Lifecycle management
 * - Keyboard handling (ESC to close)
 *
 * Use this as a base for building styled modal components.
 *
 * @example
 * ```vue
 * <template>
 *   <HeadlessModal
 *     :component="UserProfile"
 *     :component-props="{ userId: 1 }"
 *     :config="{ size: 'lg' }"
 *     base-url="/users"
 *     :open="true"
 *     @close="handleClose"
 *   >
 *     <template #default="{ modal, close }">
 *       <component :is="modal.component" v-bind="modal.props" :close="close" />
 *     </template>
 *   </HeadlessModal>
 * </template>
 * ```
 */

interface Props {
  /**
   * Unique identifier for this modal
   */
  id?: string;

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
}

interface Emits {
  (e: 'close'): void;
  (e: 'success'): void;
}

const props = withDefaults(defineProps<Props>(), {
  componentProps: () => ({}),
  config: () => ({}),
  open: true,
});

const emit = defineEmits<Emits>();

const { pushModal, popModal, emitEvent } = useModalStack();
const modalId = ref<string | null>(props.id || null);
const isClosing = ref(false);
const isOpen = ref(props.open);

// Watch for open prop changes
watch(() => props.open, (newVal) => {
  isOpen.value = newVal;
});

// Current modal data
const currentModal = computed(() => {
  if (!modalId.value) return null;
  return {
    id: modalId.value,
    component: props.component,
    props: props.componentProps,
    config: props.config,
    baseUrl: props.baseUrl,
    index: 0,
    eventHandlers: new Map(),
  };
});

// Register modal in stack when opened
watch(isOpen, (newVal) => {
  if (newVal && !modalId.value) {
    const newId = pushModal({
      component: props.component,
      props: props.componentProps,
      config: props.config,
      baseUrl: props.baseUrl,
    });
    modalId.value = newId;
  }
});

// Close modal function
async function close(success = false) {
  if (!modalId.value || isClosing.value) return;

  isClosing.value = true;

  // Emit beforeClose event - can be canceled
  const shouldClose = await emitEvent(modalId.value, 'beforeClose');
  if (!shouldClose) {
    isClosing.value = false;
    return;
  }

  // Emit close or success event
  await emitEvent(modalId.value, success ? 'success' : 'close');

  // Remove from stack
  popModal(modalId.value);

  // Call emit callbacks
  if (success) {
    emit('success');
  } else {
    emit('close');
  }

  // Navigate to base URL
  if (props.baseUrl) {
    router.visit(props.baseUrl);
  }

  modalId.value = null;
  isClosing.value = false;
  isOpen.value = false;
}

// Handle ESC key
function handleEscape(e: KeyboardEvent) {
  if (!isOpen.value || !modalId.value || props.config?.closeExplicitly) return;

  if (e.key === 'Escape') {
    e.preventDefault();
    close();
  }
}

// Setup keyboard listener
watch(isOpen, (newVal) => {
  if (newVal && !props.config?.closeExplicitly) {
    document.addEventListener('keydown', handleEscape);
  } else {
    document.removeEventListener('keydown', handleEscape);
  }
});

// Cleanup on unmount
onUnmounted(() => {
  document.removeEventListener('keydown', handleEscape);
  if (modalId.value) {
    popModal(modalId.value);
  }
});

// Initialize modal if open on mount
if (isOpen.value && !modalId.value) {
  const newId = pushModal({
    component: props.component,
    props: props.componentProps,
    config: props.config,
    baseUrl: props.baseUrl,
  });
  modalId.value = newId;
}
</script>
