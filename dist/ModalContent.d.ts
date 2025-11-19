import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines all available configuration options for modals and slideovers.
 * All fields are optional with sensible defaults.
 */
declare interface ModalConfig {
    /**
     * Size of the modal
     * @default 'md'
     *
     * Presets: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full'
     * Custom: Any valid CSS class string (e.g., 'max-w-4xl')
     */
    size?: ModalSize;
    /**
     * Position of the modal on screen
     * @default 'center'
     *
     * Presets: 'center' | 'top' | 'bottom' | 'left' | 'right'
     * Custom: Any valid CSS class string
     */
    position?: ModalPosition;
    /**
     * Whether this is a slideover (slides in from side) instead of a modal
     * @default false
     */
    slideover?: boolean;
    /**
     * Show a close button in the top-right corner
     * @default true
     */
    closeButton?: boolean;
    /**
     * Require explicit close (disables ESC key and backdrop click)
     * @default false
     */
    closeExplicitly?: boolean;
    /**
     * Custom max-width CSS value
     * @example '800px', '50rem'
     */
    maxWidth?: string;
    /**
     * Custom padding classes for modal content
     * @default 'p-6'
     * @example 'p-8', 'px-4 py-6'
     */
    paddingClasses?: string;
    /**
     * Custom panel classes for the modal container
     * @default 'bg-white rounded-lg shadow-xl'
     * @example 'bg-gray-900 text-white rounded-xl'
     */
    panelClasses?: string;
    /**
     * Custom backdrop classes for the overlay
     * @default 'bg-black/50'
     * @example 'bg-gray-900/75', 'backdrop-blur-sm'
     */
    backdropClasses?: string;
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
declare const ModalContent: default_2.ForwardRefExoticComponent<ModalContentProps & default_2.RefAttributes<HTMLDivElement>>;
export { ModalContent }
export default ModalContent;

/**
 * Props for ModalContent component
 */
export declare interface ModalContentProps {
    /**
     * Content to render inside the modal
     */
    children: default_2.ReactNode;
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
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

export { }
