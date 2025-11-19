import { default as React } from 'react';
import { ModalConfig, ModalInstance } from './types';
export { useModalStack, useModal, ModalStackProvider } from './modalStack';
export type { ModalConfig, ModalInstance, ModalEventType, ModalEventHandler } from './modalStack';
/**
 * Props for HeadlessModal component
 */
export interface HeadlessModalProps {
    /**
     * Unique identifier for this modal
     */
    id?: string;
    /**
     * Modal component to render
     */
    component: React.ComponentType<any>;
    /**
     * Props to pass to the modal component
     */
    componentProps?: Record<string, any>;
    /**
     * Modal configuration
     */
    config?: ModalConfig;
    /**
     * Base URL for the modal (used for navigation)
     */
    baseUrl: string;
    /**
     * Whether the modal is currently open
     */
    open?: boolean;
    /**
     * Callback when the modal is requested to close
     */
    onClose?: () => void;
    /**
     * Callback when the modal successfully closes
     */
    onSuccess?: () => void;
    /**
     * Children to render (for render prop pattern)
     */
    children?: (modal: ModalInstance, close: () => void) => React.ReactNode;
}
/**
 * HeadlessModal - Core modal state management
 *
 * This component provides the foundational modal logic without any UI:
 * - Modal stack integration
 * - Event system (close, success, blur, focus, beforeClose)
 * - Lifecycle management
 * - Keyboard handling (ESC to close)
 * - Focus trap
 *
 * Use this as a base for building styled modal components.
 */
export declare const HeadlessModal: React.FC<HeadlessModalProps>;
export default HeadlessModal;
//# sourceMappingURL=HeadlessModal.d.ts.map