import { default as React } from 'react';
import { ModalConfig } from './types';
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
export declare const ModalContent: React.ForwardRefExoticComponent<ModalContentProps & React.RefAttributes<HTMLDivElement>>;
export default ModalContent;
//# sourceMappingURL=ModalContent.d.ts.map