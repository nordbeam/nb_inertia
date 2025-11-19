import { default as default_2 } from 'react';

/**
 * Props for HeadlessModal component
 */
declare interface HeadlessModalProps {
    /**
     * Unique identifier for this modal
     */
    id?: string;
    /**
     * Modal component to render
     */
    component: default_2.ComponentType<any>;
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
    children?: (modal: ModalInstance, close: () => void) => default_2.ReactNode;
}

/**
 * Modal - Styled modal component using Radix UI Dialog
 *
 * This component wraps HeadlessModal with a styled UI layer using Radix UI Dialog primitives.
 * It supports:
 * - Configurable size and position
 * - Modal and slideover variants
 * - Stacked modals with proper z-indexing
 * - Custom styling through className and config
 * - Close button (optional, via children)
 * - Backdrop rendering
 *
 * @example Basic modal
 * ```tsx
 * <Modal
 *   component={UserForm}
 *   componentProps={{ userId: 1 }}
 *   baseUrl="/users"
 *   config={{
 *     size: 'lg',
 *     position: 'center',
 *     closeButton: true
 *   }}
 * >
 *   {(close) => (
 *     <>
 *       <h2>User Form</h2>
 *       <UserFormContent />
 *       <button onClick={close}>Close</button>
 *     </>
 *   )}
 * </Modal>
 * ```
 *
 * @example Slideover variant
 * ```tsx
 * <Modal
 *   component={UserEdit}
 *   componentProps={{ user }}
 *   baseUrl="/users"
 *   config={{
 *     slideover: true,
 *     position: 'right',
 *     size: 'lg'
 *   }}
 * >
 *   {(close) => <EditUserForm onClose={close} />}
 * </Modal>
 * ```
 */
declare const Modal: default_2.FC<ModalProps>;
export { Modal }
export default Modal;

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
 * Modal event handler function
 *
 * @param modal - The modal instance that emitted the event
 * @returns void, boolean, or Promise<void | boolean>
 *          - void/undefined: Event continues normally
 *          - true: Event continues (explicit confirmation)
 *          - false: Event is canceled (only for beforeClose)
 */
declare type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;

/**
 * Modal event types
 *
 * Events that can be emitted by modal instances:
 * - close: Modal is closing (can be canceled via beforeClose)
 * - success: Modal closed successfully with a success action
 * - blur: Modal lost focus (another modal opened on top)
 * - focus: Modal gained focus (became the top modal)
 * - beforeClose: About to close (return false to cancel)
 */
declare type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';

/**
 * Represents a modal instance in the stack
 *
 * This is the internal representation of a modal managed by the modal stack.
 * It contains all the information needed to render and manage the modal.
 */
declare interface ModalInstance {
    /**
     * Unique identifier for this modal
     * @example 'modal-0', 'modal-1'
     */
    id: string;
    /**
     * The React component to render inside the modal
     */
    component: default_2.ComponentType<any>;
    /**
     * Props to pass to the component
     */
    props: Record<string, any>;
    /**
     * Modal configuration (size, position, etc.)
     */
    config: ModalConfig;
    /**
     * Base URL for the modal
     *
     * When the modal closes, the browser navigates to this URL.
     * This represents the "background" page that the modal overlays.
     */
    baseUrl: string;
    /**
     * Index in the modal stack
     *
     * 0 = bottom (first modal), higher numbers = on top.
     * Used for z-indexing when multiple modals are stacked.
     */
    index: number;
    /* Excluded from this release type: eventHandlers */
}

/**
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Props for the Modal component
 */
export declare interface ModalProps extends Omit<HeadlessModalProps, 'children'> {
    /**
     * Children can be a render function or React nodes
     */
    children?: default_2.ReactNode | ((close: () => void) => default_2.ReactNode);
    /**
     * Custom class names for styling
     */
    className?: string;
}

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

export { }
