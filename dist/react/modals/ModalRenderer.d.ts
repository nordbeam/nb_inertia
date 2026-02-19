import { default as React } from 'react';
import { ModalInstance, ModalConfig } from './types';
export interface ModalRenderContext {
    /** The modal instance */
    modal: ModalInstance;
    /** Function to close this modal */
    close: () => void;
    /** Merged modal config with defaults */
    config: ModalConfig;
    /** Computed z-index for this modal */
    zIndex: number;
    /** Index in the stack (0-based) */
    index: number;
}
export interface ModalRendererProps {
    /**
     * Custom render function for each modal.
     * If not provided, uses a default rendering with backdrop and basic shell.
     */
    renderModal?: (context: ModalRenderContext) => React.ReactNode;
    /**
     * CSS classes for the backdrop overlay.
     * @default 'fixed inset-0 bg-black/50'
     */
    backdropClassName?: string;
    /**
     * CSS classes for the modal content wrapper.
     * @default 'fixed inset-0 flex items-center justify-center'
     */
    wrapperClassName?: string;
}
export declare const ModalRenderer: React.FC<ModalRendererProps>;
export default ModalRenderer;
//# sourceMappingURL=ModalRenderer.d.ts.map