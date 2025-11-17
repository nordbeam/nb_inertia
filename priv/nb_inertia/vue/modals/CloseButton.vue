<template>
  <DialogClose as-child>
    <button
      type="button"
      :class="buttonClasses"
      :aria-label="ariaLabel"
      @click="handleClose"
    >
      <svg
        :class="sizeClass"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M6 18L18 6M6 6l12 12"
        />
      </svg>
    </button>
  </DialogClose>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { DialogClose } from 'radix-vue';

/**
 * CloseButton - Accessible close button for modals using Radix Vue Dialog.Close
 *
 * Provides keyboard shortcuts (ESC is handled by Radix), configurable visibility,
 * and proper accessibility attributes.
 *
 * @example
 * ```vue
 * <template>
 *   <DialogRoot :open="open">
 *     <DialogContent>
 *       <CloseButton @close="handleClose" />
 *       <h1>Modal Content</h1>
 *     </DialogContent>
 *   </DialogRoot>
 * </template>
 * ```
 */

interface Props {
  /**
   * Additional CSS classes
   */
  class?: string;

  /**
   * Position of the close button
   */
  position?: 'top-right' | 'top-left' | 'custom';

  /**
   * Size of the button
   */
  size?: 'sm' | 'md' | 'lg';

  /**
   * Icon color classes
   */
  colorClasses?: string;

  /**
   * Accessible label
   */
  ariaLabel?: string;
}

const props = withDefaults(defineProps<Props>(), {
  position: 'top-right',
  size: 'md',
  colorClasses: 'text-gray-400 hover:text-gray-600',
  ariaLabel: 'Close',
});

const emit = defineEmits<{
  (e: 'close'): void;
}>();

/**
 * Position class mappings
 */
const POSITION_CLASSES = {
  'top-right': 'absolute top-4 right-4',
  'top-left': 'absolute top-4 left-4',
  custom: '',
};

/**
 * Size class mappings for the icon
 */
const SIZE_CLASSES = {
  sm: 'h-4 w-4',
  md: 'h-6 w-6',
  lg: 'h-8 w-8',
};

const positionClass = computed(() => POSITION_CLASSES[props.position]);
const sizeClass = computed(() => SIZE_CLASSES[props.size]);

const buttonClasses = computed(() => {
  return `
    ${positionClass.value}
    ${props.colorClasses}
    focus:outline-none
    focus:ring-2
    focus:ring-offset-2
    focus:ring-indigo-500
    rounded
    transition-colors
    ${props.class || ''}
  `.trim();
});

function handleClose() {
  emit('close');
}
</script>
