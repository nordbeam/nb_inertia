import { default as React } from 'react';
import { router as inertiaRouter } from '@inertiajs/react';
import { ModalConfig, ModalInstance } from './types';
type VisitOptions = NonNullable<Parameters<typeof inertiaRouter.visit>[1]>;
type ModalReloadOptions = Omit<VisitOptions, 'method' | 'data' | 'async'>;
export interface ModalHandle {
    modal: ModalInstance;
    id: string;
    index: number;
    onTopOfStack: boolean;
    isOpen: boolean;
    config: ModalConfig;
    close: () => void;
    setOpen: (open: boolean) => void;
    reload: (options?: ModalReloadOptions) => void;
    getParentModal: () => ModalHandle | null;
    getChildModal: () => ModalHandle | null;
}
export declare function useCurrentModal(): ModalHandle;
export interface ModalProps {
    children?: React.ReactNode | ((context: ModalHandle) => React.ReactNode);
}
export declare const Modal: React.ForwardRefExoticComponent<ModalProps & React.RefAttributes<ModalHandle>>;
export interface HeadlessModalProps {
    /** The modal instance from the stack */
    modal: ModalInstance;
    /** Called when the modal should close */
    onClose: () => void;
    /**
     * Whether the modal is currently open.
     * Custom renderers with animations can pass this through for richer context.
     * @default true
     */
    isOpen?: boolean;
    /**
     * Render function receiving modal controls and metadata.
     */
    children: (context: ModalHandle) => React.ReactNode;
}
/**
 * HeadlessModal provides modal lifecycle management without any styling.
 */
export declare const HeadlessModal: React.ForwardRefExoticComponent<HeadlessModalProps & React.RefAttributes<ModalHandle>>;
export default HeadlessModal;
//# sourceMappingURL=HeadlessModal.d.ts.map