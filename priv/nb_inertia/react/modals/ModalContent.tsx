/**
 * ModalContent Component
 *
 * Styled wrapper around Radix UI Dialog.Content with transitions, responsive sizing,
 * and accessibility attributes. Provides a consistent look and feel for
 * modal dialogs with support for different sizes and positions.
 *
 * @example
 * ```tsx
 * import * as Dialog from '@radix-ui/react-dialog';
 * import { ModalContent } from './ModalContent';
 *
 * <Dialog.Root open={open}>
 *   <Dialog.Portal>
 *     <Dialog.Overlay />
 *     <ModalContent config={{ size: 'lg', position: 'center' }}>
 *       <h1>My Modal</h1>
 *       <p>Modal content goes here</p>
 *     </ModalContent>
 *   </Dialog.Portal>
 * </Dialog.Root>
 * ```
 */

import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import type { ModalConfig } from './types';

/**
 * Props for ModalContent component
 */
export interface ModalContentProps {
  /**
   * Content to render inside the modal
   */
  children: React.ReactNode;

  /**
   * Modal configuration (size, position, styling)
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

/**
 * Position class mappings for flexbox container
 */
const POSITION_CLASSES: Record<string, string> = {
  center: 'items-center justify-center',
  top: 'items-start justify-center pt-16',
  bottom: 'items-end justify-center pb-16',
  left: 'items-center justify-start pl-16',
  right: 'items-center justify-end pr-16',
};

/**
 * Get size class from config
 */
function getSizeClass(config?: ModalConfig): string {
  const size = config?.size || 'md';

  if (typeof size === 'string' && size in SIZE_CLASSES) {
    return SIZE_CLASSES[size];
  }

  // Return as-is if it's a custom class
  return size;
}

/**
 * Get position classes from config
 */
function getPositionClasses(config?: ModalConfig): string {
  const position = config?.position || 'center';

  if (typeof position === 'string' && position in POSITION_CLASSES) {
    return POSITION_CLASSES[position];
  }

  // Return as-is if it's a custom class
  return position;
}

/**
 * Get panel classes with defaults
 */
function getPanelClasses(config?: ModalConfig): string {
  const defaults = 'bg-white rounded-lg shadow-xl';
  return config?.panelClasses ? `${defaults} ${config.panelClasses}` : defaults;
}

/**
 * Get padding classes with defaults
 */
function getPaddingClasses(config?: ModalConfig): string {
  return config?.paddingClasses || 'p-6';
}

/**
 * Get max width from config
 */
function getMaxWidth(config?: ModalConfig): string | undefined {
  return config?.maxWidth;
}

/**
 * ModalContent - Styled content wrapper for modals
 *
 * Provides a consistent, accessible modal content container with:
 * - Responsive sizing (sm, md, lg, xl, 2xl, 3xl, 4xl, 5xl, full)
 * - Flexible positioning (center, top, bottom, left, right)
 * - Smooth transitions and animations
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * This component handles the visual presentation of modal content.
 * Use Modal component for full modal functionality with state management.
 *
 * @example Basic usage
 * ```tsx
 * <ModalContent config={{ size: 'md', position: 'center' }}>
 *   <h2>Modal Title</h2>
 *   <p>Modal content</p>
 * </ModalContent>
 * ```
 *
 * @example Custom styling
 * ```tsx
 * <ModalContent
 *   config={{
 *     size: 'lg',
 *     panelClasses: 'bg-gray-900 text-white',
 *     paddingClasses: 'p-8'
 *   }}
 * >
 *   <YourContent />
 * </ModalContent>
 * ```
 *
 * @example With custom max-width
 * ```tsx
 * <ModalContent config={{ maxWidth: '800px' }}>
 *   <WideContent />
 * </ModalContent>
 * ```
 */
export const ModalContent = React.forwardRef<HTMLDivElement, ModalContentProps>(
  ({ children, config, className, zIndex = 50, onClose, ...props }, ref) => {
    const sizeClass = getSizeClass(config);
    const panelClasses = getPanelClasses(config);
    const paddingClasses = getPaddingClasses(config);
    const maxWidth = getMaxWidth(config);

    return (
      <Dialog.Content
        ref={ref}
        className={`
          fixed
          left-1/2
          top-1/2
          -translate-x-1/2
          -translate-y-1/2
          w-full
          ${sizeClass}
          ${panelClasses}
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
          ${className || ''}
        `}
        style={{ zIndex, ...(maxWidth ? { maxWidth } : {}) }}
        onEscapeKeyDown={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        onPointerDownOutside={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        onInteractOutside={config?.closeExplicitly ? (e) => e.preventDefault() : undefined}
        {...props}
      >
        <div className={paddingClasses}>{children}</div>
      </Dialog.Content>
    );
  }
);

ModalContent.displayName = 'ModalContent';

export default ModalContent;
