<template>
  <DialogContent
    :class="contentClasses"
    :style="contentStyle"
    @escape-key-down="handleEscape"
    @pointer-down-outside="handleOutsideClick"
    @interact-outside="handleOutsideClick"
  >
    <div :class="`min-h-full ${paddingClasses}`">
      <slot />
    </div>
  </DialogContent>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { DialogContent } from 'radix-vue';
import type { ModalConfig } from './types';

/**
 * SlideoverContent - Styled wrapper around Radix Vue Dialog.Content for slideov panels
 *
 * Provides a sliding panel that appears from the side of the screen with:
 * - Smooth slide-in transitions from any direction (left, right, top, bottom)
 * - Responsive sizing (sm, md, lg, xl, 2xl, full)
 * - Vertical scrolling for overflow content
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * @example
 * ```vue
 * <template>
 *   <DialogRoot :open="open">
 *     <DialogPortal>
 *       <DialogOverlay />
 *       <SlideoverContent :config="{ position: 'right', size: 'md' }">
 *         <h2>Edit User</h2>
 *         <form>...</form>
 *       </SlideoverContent>
 *     </DialogPortal>
 *   </DialogRoot>
 * </template>
 * ```
 */

interface Props {
  /**
   * Modal/slideover configuration
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

/**
 * Slideover width/height classes based on size
 */
const SLIDEOVER_SIZE_CLASSES: Record<string, string> = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
  '2xl': 'max-w-2xl',
  full: 'max-w-full',
};

/**
 * Position classes for slideover (fixed positioning)
 */
const SLIDEOVER_POSITION_CLASSES: Record<string, string> = {
  left: 'inset-y-0 left-0',
  right: 'inset-y-0 right-0',
  top: 'inset-x-0 top-0',
  bottom: 'inset-x-0 bottom-0',
};

/**
 * Animation classes based on slide direction for Radix data-state
 */
const SLIDE_ANIMATION_CLASSES: Record<string, string> = {
  left: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-left
    data-[state=open]:slide-in-from-left
  `,
  right: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-right
    data-[state=open]:slide-in-from-right
  `,
  top: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-top
    data-[state=open]:slide-in-from-top
  `,
  bottom: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-bottom
    data-[state=open]:slide-in-from-bottom
  `,
};

const sizeClass = computed(() => {
  const size = props.config?.size || 'md';
  return SLIDEOVER_SIZE_CLASSES[size as string] || size;
});

const positionClass = computed(() => {
  const position = props.config?.position || 'right';
  return SLIDEOVER_POSITION_CLASSES[position as string] || SLIDEOVER_POSITION_CLASSES.right;
});

const animationClasses = computed(() => {
  const position = props.config?.position || 'right';
  return SLIDE_ANIMATION_CLASSES[position as string] || SLIDE_ANIMATION_CLASSES.right;
});

const panelClasses = computed(() => {
  const defaults = 'bg-white shadow-xl';
  return props.config?.panelClasses ? `${defaults} ${props.config.panelClasses}` : defaults;
});

const paddingClasses = computed(() => {
  return props.config?.paddingClasses || 'p-6';
});

const isHorizontal = computed(() => {
  const position = props.config?.position || 'right';
  return position === 'left' || position === 'right';
});

const contentClasses = computed(() => {
  return `
    fixed
    ${positionClass.value}
    ${isHorizontal.value ? 'h-full' : 'w-full'}
    ${isHorizontal.value ? sizeClass.value : ''}
    ${panelClasses.value}
    transform
    transition-all
    duration-300
    ease-out
    ${animationClasses.value}
    overflow-y-auto
    ${props.class || ''}
  `.trim();
});

const contentStyle = computed(() => ({
  zIndex: props.zIndex,
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
