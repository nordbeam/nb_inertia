<template>
  <DialogContent
    :class="contentClasses"
    :style="contentStyle"
    @escape-key-down="handleEscape"
    @pointer-down-outside="handleOutsideClick"
    @interact-outside="handleOutsideClick"
  >
    <div :class="paddingClasses">
      <slot />
    </div>
  </DialogContent>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { DialogContent } from 'radix-vue';
import type { ModalConfig } from './types';

/**
 * ModalContent - Styled wrapper around Radix Vue Dialog.Content
 *
 * Provides a styled modal content container with:
 * - Responsive sizing (sm, md, lg, xl, 2xl, 3xl, 4xl, 5xl, full)
 * - Smooth transitions and animations via Radix data-state
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * @example
 * ```vue
 * <template>
 *   <DialogRoot :open="open">
 *     <DialogPortal>
 *       <DialogOverlay />
 *       <ModalContent :config="{ size: 'lg', position: 'center' }">
 *         <h1>Modal Title</h1>
 *         <p>Modal content</p>
 *       </ModalContent>
 *     </DialogPortal>
 *   </DialogRoot>
 * </template>
 * ```
 */

interface Props {
  /**
   * Modal configuration (size, position, styling)
   */
  config?: ModalConfig;

  /**
   * Additional CSS classes
   */
  class?: string;

  /**
   * Z-index for stacking
   */
  zIndex?: number;
}

const props = withDefaults(defineProps<Props>(), {
  config: () => ({}),
  zIndex: 50,
});

const emit = defineEmits<{
  (e: 'close'): void;
}>();

/**
 * Size class mappings
 */
const SIZE_CLASSES: Record<string, string> = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
  '2xl': 'max-w-2xl',
  '3xl': 'max-w-3xl',
  '4xl': 'max-w-4xl',
  '5xl': 'max-w-5xl',
  full: 'max-w-full',
};

const sizeClass = computed(() => {
  const size = props.config?.size || 'md';
  return SIZE_CLASSES[size as string] || size;
});

const panelClasses = computed(() => {
  const defaults = 'bg-white rounded-lg shadow-xl';
  return props.config?.panelClasses ? `${defaults} ${props.config.panelClasses}` : defaults;
});

const paddingClasses = computed(() => {
  return props.config?.paddingClasses || 'p-6';
});

const contentClasses = computed(() => {
  return `
    fixed
    left-1/2
    top-1/2
    -translate-x-1/2
    -translate-y-1/2
    w-full
    ${sizeClass.value}
    ${panelClasses.value}
    transform
    transition-all
    duration-300
    ease-out
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:zoom-out-95
    data-[state=open]:zoom-in-95
    data-[state=closed]:slide-out-to-left-1/2
    data-[state=closed]:slide-out-to-top-[48%]
    data-[state=open]:slide-in-from-left-1/2
    data-[state=open]:slide-in-from-top-[48%]
    ${props.class || ''}
  `.trim();
});

const contentStyle = computed(() => ({
  zIndex: props.zIndex,
  ...(props.config?.maxWidth ? { maxWidth: props.config.maxWidth } : {}),
}));

function handleEscape(e: Event) {
  if (props.config?.closeExplicitly) {
    e.preventDefault();
  }
}

function handleOutsideClick(e: Event) {
  if (props.config?.closeExplicitly) {
    e.preventDefault();
  }
}
</script>
