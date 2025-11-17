/**
 * CloseButton Component
 *
 * Accessible close button for modals and slideovers using Radix UI Dialog.Close.
 * Provides keyboard shortcuts (ESC is handled by Radix), configurable visibility,
 * and proper accessibility attributes.
 *
 * @example
 * ```tsx
 * import * as Dialog from '@radix-ui/react-dialog';
 * import { CloseButton } from './CloseButton';
 *
 * <Dialog.Root>
 *   <Dialog.Content>
 *     <CloseButton onClose={handleClose} />
 *     <h1>Modal Content</h1>
 *   </Dialog.Content>
 * </Dialog.Root>
 * ```
 */

import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';

/**
 * Props for CloseButton component
 */
export interface CloseButtonProps {
  /**
   * Close handler callback
   */
  onClose?: () => void;

  /**
   * Additional CSS classes
   */
  className?: string;

  /**
   * Position of the close button
   * @default 'top-right'
   */
  position?: 'top-right' | 'top-left' | 'custom';

  /**
   * Size of the button
   * @default 'md'
   */
  size?: 'sm' | 'md' | 'lg';

  /**
   * Icon color classes
   * @default 'text-gray-400 hover:text-gray-600'
   */
  colorClasses?: string;

  /**
   * Accessible label
   * @default 'Close'
   */
  ariaLabel?: string;
}

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

/**
 * CloseButton - Accessible close button for modals
 *
 * Wraps Radix UI Dialog.Close with a styled close icon button.
 * Features:
 * - Accessible with proper ARIA labels
 * - Keyboard navigation support (Tab, Enter, Space)
 * - ESC key handled automatically by Radix Dialog
 * - Configurable position, size, and colors
 * - Focus ring for keyboard users
 *
 * @example Basic usage
 * ```tsx
 * <CloseButton onClose={handleClose} />
 * ```
 *
 * @example Custom position and size
 * ```tsx
 * <CloseButton
 *   position="top-left"
 *   size="lg"
 *   onClose={handleClose}
 * />
 * ```
 *
 * @example Custom colors
 * ```tsx
 * <CloseButton
 *   colorClasses="text-red-400 hover:text-red-600"
 *   onClose={handleClose}
 * />
 * ```
 *
 * @example Custom positioning
 * ```tsx
 * <CloseButton
 *   position="custom"
 *   className="bottom-4 right-4"
 *   onClose={handleClose}
 * />
 * ```
 */
export const CloseButton: React.FC<CloseButtonProps> = ({
  onClose,
  className,
  position = 'top-right',
  size = 'md',
  colorClasses = 'text-gray-400 hover:text-gray-600',
  ariaLabel = 'Close',
}) => {
  const positionClass = POSITION_CLASSES[position];
  const sizeClass = SIZE_CLASSES[size];

  return (
    <Dialog.Close asChild>
      <button
        type="button"
        className={`
          ${positionClass}
          ${colorClasses}
          focus:outline-none
          focus:ring-2
          focus:ring-offset-2
          focus:ring-indigo-500
          rounded
          transition-colors
          ${className || ''}
        `}
        onClick={onClose}
        aria-label={ariaLabel}
      >
        <svg
          className={sizeClass}
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </Dialog.Close>
  );
};

export default CloseButton;
