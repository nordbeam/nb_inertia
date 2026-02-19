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
 * This interface defines behavioral configuration options for modals.
 * Styling is left to the user's UI implementation.
 * All fields are optional with sensible defaults.
 */
export interface ModalConfig {
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
    loadingComponent?: React.ComponentType;
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
     * @param modal - Modal data without id (auto-generated)
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
    pushModal: (modal: Omit<ModalInstance, 'id'>) => string;
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
     * Clear all modals from the stack.
     *
     * By default does NOT fire onClose callbacks (designed for navigation).
     * Pass `{ fireOnClose: true }` to invoke each modal's onClose.
     *
     * @example
     * ```tsx
     * clearModals(); // Close all, no callbacks
     * clearModals({ fireOnClose: true }); // Close all with callbacks
     * ```
     */
    clearModals: (options?: {
        fireOnClose?: boolean;
    }) => void;
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
     * Update an existing modal's properties
     *
     * Used to replace a loading modal's placeholder content with actual content
     * when the server response arrives.
     *
     * @param id - ID of the modal to update
     * @param updates - Partial modal data to merge with existing modal
     *
     * @example
     * ```tsx
     * // Update a loading modal with actual content
     * updateModal('modal-0', {
     *   component: ActualComponent,
     *   componentName: 'Users/Show',
     *   props: { user: fetchedUser },
     *   loading: false,
     * });
     * ```
     */
    updateModal: (id: string, updates: Partial<Omit<ModalInstance, 'id'>>) => void;
    /**
     * Function to resolve component names to React components.
     * This is provided by the app and used for prefetching component modules.
     *
     * Returns undefined if not provided to ModalStackProvider.
     */
    resolveComponent?: (name: string) => Promise<React.ComponentType<any>>;
    /**
     * Prefetch data and component for a modal URL.
     * Only available if resolveComponent is provided.
     *
     * This handles:
     * 1. Prefetching page data via Inertia
     * 2. Preloading the React component module
     *
     * @param url - The URL to prefetch
     * @param options - Prefetch options
     */
    prefetchModal?: (url: string, options?: {
        cacheFor?: number;
    }) => void;
    /**
     * Cache of prefetched modal data
     * Maps URL to { data, component, timestamp }
     */
    getPrefetchedModal?: (url: string) => PrefetchedModal | undefined;
}
/**
 * Cached prefetch data for a modal
 */
export interface PrefetchedModal {
    /** The prefetched page data (from _nb_modal) */
    data: {
        component: string;
        props: Record<string, any>;
        url: string;
        baseUrl: string;
        config?: ModalConfig;
    };
    /** The resolved React component */
    component: React.ComponentType<any>;
    /** When this was prefetched */
    timestamp: number;
}
/**
 * Default behavioral modal configuration
 *
 * These are the default behavioral values. UI styling defaults
 * should be defined in your own modal renderer implementation.
 */
export declare const DEFAULT_MODAL_CONFIG: {
    size: ModalSize;
    position: ModalPosition;
    slideover: boolean;
    closeButton: boolean;
    closeExplicitly: boolean;
};
/**
 * Merge user config with behavioral defaults
 *
 * @param config - User-provided configuration
 * @returns Merged configuration with defaults
 */
export declare function mergeModalConfig(config?: ModalConfig): ModalConfig;
/**
 * Helper type for accessing typed modal props.
 *
 * Since the modal stack manages heterogeneous modals, ModalInstance.props
 * is `Record<string, any>` internally. Use this type to narrow props in
 * your modal components.
 *
 * @example
 * ```tsx
 * type UserModalProps = { user: User; canEdit: boolean };
 *
 * function UserModal({ user, canEdit }: TypedModalProps<UserModalProps>) {
 *   // Props are fully typed here
 * }
 * ```
 */
export type TypedModalProps<TProps extends Record<string, unknown>> = TProps;
/**
 * A modal instance with typed props.
 *
 * Use this when you know the shape of a specific modal's props.
 *
 * @example
 * ```tsx
 * const modal = getModal(id) as TypedModalInstance<{ user: User }> | undefined;
 * if (modal) {
 *   console.log(modal.props.user.name); // Typed!
 * }
 * ```
 */
export type TypedModalInstance<TProps extends Record<string, unknown> = Record<string, unknown>> = Omit<ModalInstance, 'props'> & {
    props: TProps;
};
//# sourceMappingURL=types.d.ts.map