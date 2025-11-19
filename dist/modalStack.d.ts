import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines all available configuration options for modals and slideovers.
 * All fields are optional with sensible defaults.
 */
export declare interface ModalConfig {
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
export declare type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;

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
export declare type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';

/**
 * Represents a modal instance in the stack
 *
 * This is the internal representation of a modal managed by the modal stack.
 * It contains all the information needed to render and manage the modal.
 */
export declare interface ModalInstance {
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
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

/**
 * Modal stack manager context value
 *
 * This is the API provided by ModalStackProvider to manage modals.
 */
export declare interface ModalStackContextValue {
    /**
     * Array of currently active modals (bottom to top)
     */
    modals: ModalInstance[];
    /**
     * Push a new modal onto the stack
     *
     * @param modal - Modal data without id, index, and eventHandlers (auto-generated)
     * @returns The ID of the newly created modal
     *
     * @example
     * ```tsx
     * const id = pushModal({
     *   component: UserProfile,
     *   props: { userId: 1 },
     *   config: { size: 'lg' },
     *   baseUrl: '/users'
     * });
     * ```
     */
    pushModal: (modal: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>) => string;
    /**
     * Remove a modal from the stack by ID
     *
     * @param id - ID of the modal to remove
     *
     * @example
     * ```tsx
     * popModal('modal-0');
     * ```
     */
    popModal: (id: string) => void;
    /**
     * Clear all modals from the stack
     *
     * @example
     * ```tsx
     * clearModals(); // Close all open modals
     * ```
     */
    clearModals: () => void;
    /**
     * Get a modal instance by ID
     *
     * @param id - ID of the modal to find
     * @returns The modal instance or undefined if not found
     *
     * @example
     * ```tsx
     * const modal = getModal('modal-0');
     * if (modal) {
     *   console.log('Modal config:', modal.config);
     * }
     * ```
     */
    getModal: (id: string) => ModalInstance | undefined;
    /**
     * Register an event listener for a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to listen for
     * @param handler - Event handler function
     *
     * @example
     * ```tsx
     * addEventListener('modal-0', 'beforeClose', async (modal) => {
     *   const confirmed = await confirm('Close modal?');
     *   return confirmed; // Return false to cancel close
     * });
     * ```
     */
    addEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
    /**
     * Remove an event listener from a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to remove handler for
     * @param handler - Event handler function to remove
     *
     * @example
     * ```tsx
     * removeEventListener('modal-0', 'close', myHandler);
     * ```
     */
    removeEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
    /**
     * Emit an event for a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to emit
     * @returns Promise resolving to true if event should continue, false if canceled
     *
     * @example
     * ```tsx
     * const shouldClose = await emitEvent('modal-0', 'beforeClose');
     * if (shouldClose) {
     *   // Proceed with close
     * }
     * ```
     */
    emitEvent: (id: string, event: ModalEventType) => Promise<boolean>;
}

/**
 * Provider for the modal stack
 *
 * Wraps your application to provide modal stack management to all child components.
 * Must be placed high in your component tree, typically near the root.
 *
 * @param props - Provider props
 *
 * @example
 * ```tsx
 * import { ModalStackProvider } from './modalStack';
 *
 * function App() {
 *   return (
 *     <ModalStackProvider>
 *       <Router>
 *         <YourRoutes />
 *       </Router>
 *     </ModalStackProvider>
 *   );
 * }
 * ```
 *
 * @example With stack change callback
 * ```tsx
 * function App() {
 *   const handleStackChange = (modals) => {
 *     console.log('Modal stack updated:', modals.length, 'modals');
 *   };
 *
 *   return (
 *     <ModalStackProvider onStackChange={handleStackChange}>
 *       <YourApp />
 *     </ModalStackProvider>
 *   );
 * }
 * ```
 */
declare const ModalStackProvider: default_2.FC<ModalStackProviderProps>;
export { ModalStackProvider }
export default ModalStackProvider;

/**
 * Props for ModalStackProvider
 */
export declare interface ModalStackProviderProps {
    /**
     * Child components that can access the modal stack
     */
    children: default_2.ReactNode;
    /**
     * Optional callback when modal stack changes
     */
    onStackChange?: (modals: ModalInstance[]) => void;
}

/**
 * Hook to access the current modal instance
 *
 * Returns the topmost modal in the stack (the currently focused modal).
 * Returns null if no modals are open.
 *
 * @returns The current modal instance or null
 *
 * @example
 * ```tsx
 * function ModalContent() {
 *   const modal = useModal();
 *
 *   if (!modal) {
 *     return <div>No modal open</div>;
 *   }
 *
 *   return (
 *     <div>
 *       <h1>Modal {modal.id}</h1>
 *       <p>Index in stack: {modal.index}</p>
 *     </div>
 *   );
 * }
 * ```
 */
export declare const useModal: () => ModalInstance | null;

/**
 * Hook to access the modal stack
 *
 * Must be used within a ModalStackProvider.
 *
 * @throws Error if used outside ModalStackProvider
 * @returns The modal stack context value
 *
 * @example
 * ```tsx
 * function MyComponent() {
 *   const { pushModal, modals } = useModalStack();
 *
 *   const openModal = () => {
 *     pushModal({
 *       component: UserProfile,
 *       props: { userId: 1 },
 *       config: { size: 'lg' },
 *       baseUrl: '/users'
 *     });
 *   };
 *
 *   return (
 *     <div>
 *       <button onClick={openModal}>Open Modal</button>
 *       <p>Active modals: {modals.length}</p>
 *     </div>
 *   );
 * }
 * ```
 */
export declare const useModalStack: () => ModalStackContextValue;

export { }
