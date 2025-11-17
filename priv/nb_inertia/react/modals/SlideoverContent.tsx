/**
 * SlideoverContent Component
 *
 * Styled wrapper around Radix UI Dialog.Content for slideover panels that slide in from the sides.
 * Provides smooth transitions, responsive sizing, and accessibility attributes.
 *
 * @example
 * ```tsx
 * import * as Dialog from '@radix-ui/react-dialog';
 * import { SlideoverContent } from './SlideoverContent';
 *
 * <Dialog.Root open={open}>
 *   <Dialog.Portal>
 *     <Dialog.Overlay />
 *     <SlideoverContent config={{ position: 'right', size: 'md' }}>
 *       <h1>Slideover Panel</h1>
 *       <p>Content slides in from the right</p>
 *     </SlideoverContent>
 *   </Dialog.Portal>
 * </Dialog.Root>
 * ```
 */

import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import type { ModalConfig } from './types';

/**
 * Props for SlideoverContent component
 */
export interface SlideoverContentProps {
  /**
   * Content to render inside the slideover
   */
  children: React.ReactNode;

  /**
   * Modal/slideover configuration
   */
  config?: ModalConfig;

  /**
   * Additional CSS classes
   */
  className?: string;

  /**
   * Z-index for stacking
   */
  zIndex?: number;

  /**
   * Close handler
   */
  onClose?: () => void;
}

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

/**
 * Get size class from config
 */
function getSizeClass(config?: ModalConfig): string {
  const size = config?.size || 'md';

  if (typeof size === 'string' && size in SLIDEOVER_SIZE_CLASSES) {
    return SLIDEOVER_SIZE_CLASSES[size];
  }

  return size;
}

/**
 * Get position classes from config
 */
function getPositionClasses(config?: ModalConfig): string {
  const position = config?.position || 'right';

  if (typeof position === 'string' && position in SLIDEOVER_POSITION_CLASSES) {
    return SLIDEOVER_POSITION_CLASSES[position];
  }

  // Default to right if custom position
  return SLIDEOVER_POSITION_CLASSES.right;
}

/**
 * Get animation classes based on position
 */
function getAnimationClasses(config?: ModalConfig): string {
  const position = config?.position || 'right';

  if (typeof position === 'string' && position in SLIDE_ANIMATION_CLASSES) {
    return SLIDE_ANIMATION_CLASSES[position];
  }

  // Default to right if custom position
  return SLIDE_ANIMATION_CLASSES.right;
}

/**
 * Get panel classes with defaults
 */
function getPanelClasses(config?: ModalConfig): string {
  const defaults = 'bg-white shadow-xl';
  return config?.panelClasses ? `${defaults} ${config.panelClasses}` : defaults;
}

/**
 * Get padding classes with defaults
 */
function getPaddingClasses(config?: ModalConfig): string {
  return config?.paddingClasses || 'p-6';
}

/**
 * Check if position is horizontal (left/right)
 */
function isHorizontal(position?: string): boolean {
  return position === 'left' || position === 'right' || !position;
}

/**
 * SlideoverContent - Styled content wrapper for slideover panels
 *
 * Provides a sliding panel that appears from the side of the screen with:
 * - Smooth slide-in transitions from any direction (left, right, top, bottom)
 * - Responsive sizing (sm, md, lg, xl, 2xl, full)
 * - Vertical scrolling for overflow content
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * Slideovers are ideal for:
 * - Forms and edit panels
 * - Navigation menus
 * - Filters and settings
 * - Secondary content that doesn't need full page focus
 *
 * @example Basic usage
 * ```tsx
 * <SlideoverContent config={{ position: 'right', size: 'md' }}>
 *   <h2>Edit User</h2>
 *   <form>...</form>
 * </SlideoverContent>
 * ```
 *
 * @example Left side navigation
 * ```tsx
 * <SlideoverContent config={{ position: 'left', size: 'sm' }}>
 *   <nav>
 *     <ul>...</ul>
 *   </nav>
 * </SlideoverContent>
 * ```
 *
 * @example Full width top banner
 * ```tsx
 * <SlideoverContent config={{ position: 'top', size: 'full' }}>
 *   <div className="h-48">
 *     <p>Notification banner</p>
 *   </div>
 * </SlideoverContent>
 * ```
 *
 * @example Custom styling
 * ```tsx
 * <SlideoverContent
 *   config={{
 *     position: 'right',
 *     panelClasses: 'bg-gray-900 text-white',
 *     paddingClasses: 'p-8'
 *   }}
 * >
 *   <DarkModeContent />
 * </SlideoverContent>
 * ```
 */
export const SlideoverContent = React.forwardRef<HTMLDivElement, SlideoverContentProps>(
  ({ children, config, className, zIndex = 50, onClose, ...props }, ref) => {
    const sizeClass = getSizeClass(config);
    const containerClass = getPositionClasses(config);
    const animationClasses = getAnimationClasses(config);
    const panelClasses = getPanelClasses(config);
    const paddingClasses = getPaddingClasses(config);
    const horizontal = isHorizontal(config?.position);

    return (
      <Dialog.Content
        ref={ref}
        className={`
          fixed
          ${containerClass}
          ${horizontal ? 'h-full' : 'w-full'}
          ${horizontal ? sizeClass : ''}
          ${panelClasses}
          transform
          transition-all
          duration-300
          ease-out
          ${animationClasses}
          overflow-y-auto
          ${className || ''}
        `}
        style={{ zIndex }}
        onEscapeKeyDown={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        onPointerDownOutside={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        onInteractOutside={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        {...props}
      >
        <div className={`min-h-full ${paddingClasses}`}>{children}</div>
      </Dialog.Content>
    );
  }
);

SlideoverContent.displayName = 'SlideoverContent';

export default SlideoverContent;
