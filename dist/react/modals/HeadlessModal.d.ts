import { ModalInstance, ModalConfig } from './types';
export interface HeadlessModalProps {
    /** The modal instance from the stack */
    modal: ModalInstance;
    /** Called when the modal should close */
    onClose: () => void;
    /**
     * Render function receiving a close handler.
     * The close handler triggers onClose after any beforeClose logic.
     */
    children: (context: {
        close: () => void;
        config: ModalConfig;
    }) => React.ReactNode;
}
/**
 * HeadlessModal provides modal lifecycle management without any styling.
 *
 * It handles:
 * - ESC key to close (unless closeExplicitly is true)
 * - Preventing close during transition
 * - Providing a close function to children
 */
export declare function HeadlessModal({ modal, onClose, children }: HeadlessModalProps): import("react/jsx-runtime").JSX.Element;
export default HeadlessModal;
//# sourceMappingURL=HeadlessModal.d.ts.map