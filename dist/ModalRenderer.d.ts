import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines behavioral configuration options for modals.
 * Styling is left to the user's UI implementation.
 * All fields are optional with sensible defaults.
 */
declare interface ModalConfig {
    /**
     * Size hint for the modal
     * @default 'md'
     *
     * Presets: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full'
     * Your UI implementation can interpret this however you like.
     */
    size?: ModalSize;
    /**
     * Position hint for the modal
     * @default 'center'
     *
     * Presets: 'center' | 'top' | 'bottom' | 'left' | 'right'
     * Your UI implementation can interpret this however you like.
     */
    position?: ModalPosition;
    /**
     * Whether this is a slideover (slides in from side) instead of a centered modal
     * @default false
     */
    slideover?: boolean;
    /**
     * Whether to show a close button
     * @default true
     */
    closeButton?: boolean;
    /**
     * Require explicit close (disables ESC key and backdrop click)
     * @default false
     */
    closeExplicitly?: boolean;
    /**
     * Any additional custom data your UI implementation needs
     * This is passed through to your modal renderer unchanged.
     */
    [key: string]: unknown;
}

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
     * The component name (e.g., "Users/Edit") for page context
     */
    componentName: string;
    /**
     * Props to pass to the component
     */
    props: Record<string, any>;
    /**
     * The URL of the modal page (for page context)
     */
    url: string;
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
     * The full URL (including query params) to return to when the modal closes
     *
     * This captures the exact URL the user was on before opening the modal,
     * preserving query parameters like pagination, filters, and sorting.
     * If not set, falls back to baseUrl.
     */
    returnUrl?: string;
    /**
     * Callback invoked when the modal is closed
     */
    onClose?: () => void;
    /**
     * Whether the modal is in a loading state (waiting for content)
     *
     * When true, the modal shell is displayed with a loading indicator
     * while the actual content is being fetched from the server.
     * @default false
     */
    loading?: boolean;
    /**
     * Custom loading component to display while loading
     *
     * If not provided, a default spinner/skeleton will be shown.
     * This allows customizing the loading UI per modal.
     */
    loadingComponent?: default_2.ComponentType;
}

/**
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

export declare interface ModalRenderContext {
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

declare const ModalRenderer: default_2.FC<ModalRendererProps>;
export { ModalRenderer }
export default ModalRenderer;

export declare interface ModalRendererProps {
    /**
     * Custom render function for each modal.
     * If not provided, uses a default rendering with backdrop and basic shell.
     */
    renderModal?: (context: ModalRenderContext) => default_2.ReactNode;
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

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

export { }
