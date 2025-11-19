import { default as React } from 'react';
/**
 * Modal size presets and custom sizes
 */
export type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;
/**
 * Modal position presets and custom positions
 */
export type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;
/**
 * Configuration for a modal instance
 *
 * This interface defines all available configuration options for modals and slideovers.
 * All fields are optional with sensible defaults.
 */
export interface ModalConfig {
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
 * Modal event types
 *
 * Events that can be emitted by modal instances:
 * - close: Modal is closing (can be canceled via beforeClose)
 * - success: Modal closed successfully with a success action
 * - blur: Modal lost focus (another modal opened on top)
 * - focus: Modal gained focus (became the top modal)
 * - beforeClose: About to close (return false to cancel)
 */
export type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';
/**
 * Modal event handler function
 *
 * @param modal - The modal instance that emitted the event
 * @returns void, boolean, or Promise<void | boolean>
 *          - void/undefined: Event continues normally
 *          - true: Event continues (explicit confirmation)
 *          - false: Event is canceled (only for beforeClose)
 */
export type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;
/**
 * Represents a modal instance in the stack
 *
 * This is the internal representation of a modal managed by the modal stack.
 * It contains all the information needed to render and manage the modal.
 */
export interface ModalInstance {
    /**
     * Unique identifier for this modal
     * @example 'modal-0', 'modal-1'
     */
    id: string;
    /**
     * The React component to render inside the modal
     */
    component: React.ComponentType<any>;
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
    /**
     * Event handlers registered for this modal
     * @internal
     */
    eventHandlers: Map<ModalEventType, Set<ModalEventHandler>>;
}
/**
 * Modal stack manager context value
 *
 * This is the API provided by ModalStackProvider to manage modals.
 */
export interface ModalStackContextValue {
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
 * Default modal configuration
 *
 * These are the default values used when configuration options are not specified.
 */
export declare const DEFAULT_MODAL_CONFIG: Required<ModalConfig>;
/**
 * Merge user config with defaults
 *
 * @param config - User-provided configuration
 * @returns Merged configuration with defaults
 */
export declare function mergeModalConfig(config?: ModalConfig): Required<ModalConfig>;
//# sourceMappingURL=types.d.ts.map