import { default as default_2 } from 'react';

/**
 * Configuration for a modal instance
 *
 * This interface defines behavioral configuration options for modals.
 * Styling is left to the user's UI implementation.
 * All fields are optional with sensible defaults.
 */
export declare interface ModalConfig {
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
 * Inertia Page object structure for modal context
 */
export declare interface ModalPageObject {
    component: string;
    props: Record<string, any>;
    url: string;
    version?: string;
    scrollRegions?: Array<{
        top: number;
        left: number;
    }>;
    rememberedState?: Record<string, unknown>;
    clearHistory?: boolean;
    encryptHistory?: boolean;
}

export declare const ModalPageProvider: default_2.FC<ModalPageProviderProps>;

/**
 * Provider component that wraps modal content with page context
 * This should be used by modal renderers to provide page data to modal content
 */
export declare interface ModalPageProviderProps {
    component: string;
    props: Record<string, any>;
    url: string;
    children: default_2.ReactNode;
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
    resolveComponent?: (name: string) => Promise<default_2.ComponentType<any>>;
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
    /**
     * Function to resolve component names to React components.
     * When provided, enables ModalLink to prefetch both data AND component modules
     * for instant modal opening.
     *
     * @example
     * ```tsx
     * const pages = import.meta.glob('./pages/**\/*.tsx');
     * const resolveComponent = (name: string) =>
     *   pages[`./pages/${name}.tsx`]().then((m: any) => m.default);
     *
     * <ModalStackProvider resolveComponent={resolveComponent}>
     *   <App />
     * </ModalStackProvider>
     * ```
     */
    resolveComponent?: ResolveComponentFn;
}

/**
 * Cached prefetch data for a modal
 */
declare interface PrefetchedModal {
    /** The prefetched page data (from _nb_modal) */
    data: {
        component: string;
        props: Record<string, any>;
        url: string;
        baseUrl: string;
        config?: ModalConfig;
    };
    /** The resolved React component */
    component: default_2.ComponentType<any>;
    /** When this was prefetched */
    timestamp: number;
}

/**
 * Function type for resolving component names to React components
 */
export declare type ResolveComponentFn = (name: string) => Promise<default_2.ComponentType<any>>;

/**
 * Hook to check if we're inside a modal context
 * @returns true if component is rendered inside a modal
 */
export declare function useIsInModal(): boolean;

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
 * Hook to get the modal's page object
 * Returns null if not in a modal context
 */
export declare function useModalPageContext(): ModalPageObject | null;

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
