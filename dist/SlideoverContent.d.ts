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
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

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
declare const SlideoverContent: default_2.ForwardRefExoticComponent<SlideoverContentProps & default_2.RefAttributes<HTMLDivElement>>;
export { SlideoverContent }
export default SlideoverContent;

/**
 * Props for SlideoverContent component
 */
export declare interface SlideoverContentProps {
    /**
     * Content to render inside the slideover
     */
    children: default_2.ReactNode;
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

export { }
