/**
 * Handles initial modal detection and navigation events
 *
 * This component:
 * - Detects `_nb_modal` prop on initial page load (direct URL access)
 * - Listens for Inertia navigation events with modal data
 * - Pushes modals onto the stack via useModalStack
 * - Manages browser history for proper back/forward navigation
 */
declare function InitialModalHandler({ resolveComponent }: InitialModalHandlerProps): null;
export { InitialModalHandler }
export default InitialModalHandler;

/**
 * Props for InitialModalHandler component
 */
export declare interface InitialModalHandlerProps {
    /**
     * Function to resolve a component name to a React component
     *
     * @example
     * ```tsx
     * // Using Vite's import.meta.glob
     * const pages = import.meta.glob('./pages/**\/*.tsx');
     * const resolveComponent = (name: string) =>
     *   pages[`./pages/${name}.tsx`]().then((m: any) => m.default);
     * ```
     */
    resolveComponent: (name: string) => Promise<React.ComponentType<any>>;
}

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
 * Modal data structure from the backend's render_inertia_modal response
 *
 * This is injected into page props as `_nb_modal` by the backend when
 * rendering a modal response.
 */
export declare interface ModalOnBase {
    /** The component name to render (e.g., "Users/Show") */
    component: string;
    /** Props to pass to the modal component */
    props: Record<string, any>;
    /** The URL of the modal page */
    url: string;
    /** Base URL for the backdrop page */
    baseUrl: string;
    /** Optional modal configuration */
    config?: ModalConfig;
}

/**
 * Modal position presets and custom positions
 */
declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Modal size presets and custom sizes
 */
declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

export { }
