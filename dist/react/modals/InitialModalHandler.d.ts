import { ModalConfig } from './types';
/**
 * Modal data structure from the backend's render_inertia_modal response
 *
 * This is injected into page props as `_nb_modal` by the backend when
 * rendering a modal response.
 */
export interface ModalOnBase {
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
 * Props for InitialModalHandler component
 */
export interface InitialModalHandlerProps {
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
 * Handles initial modal detection and navigation events
 *
 * This component:
 * - Detects `_nb_modal` prop on initial page load (direct URL access)
 * - Listens for Inertia navigation events with modal data
 * - Pushes modals onto the stack via useModalStack
 * - Manages browser history for proper back/forward navigation
 */
export declare function InitialModalHandler({ resolveComponent }: InitialModalHandlerProps): null;
export default InitialModalHandler;
//# sourceMappingURL=InitialModalHandler.d.ts.map