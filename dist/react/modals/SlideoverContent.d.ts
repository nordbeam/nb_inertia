import { default as React } from 'react';
import { ModalConfig } from './types';
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
export declare const SlideoverContent: React.ForwardRefExoticComponent<SlideoverContentProps & React.RefAttributes<HTMLDivElement>>;
export default SlideoverContent;
//# sourceMappingURL=SlideoverContent.d.ts.map