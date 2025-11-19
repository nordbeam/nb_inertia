import { default as React } from 'react';
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
export declare const CloseButton: React.FC<CloseButtonProps>;
export default CloseButton;
//# sourceMappingURL=CloseButton.d.ts.map