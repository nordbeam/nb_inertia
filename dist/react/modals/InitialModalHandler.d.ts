import { Page as InertiaPage } from '@inertiajs/core';
import { ModalConfig, ModalPageMetadata } from './types';
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
    /** Optional page metadata when the modal payload is supplied directly. */
    pageMetadata?: ModalPageMetadata;
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
    /**
     * The initial Inertia page supplied to `createInertiaApp`'s `withApp` or
     * `setup` callback. This avoids coupling the handler to React's internal page
     * context and lets the modal provider wrap the entire Inertia application.
     */
    initialPage?: InertiaPage;
}
/**
 * Mount the modal event bridge with an explicit initial page (recommended for
 * Inertia v3 `withApp` wrappers) or, for backward compatibility, inside the
 * Inertia component tree where the official `usePage` context is available.
 */
export declare function InitialModalHandler({ resolveComponent, initialPage }: InitialModalHandlerProps): import("react").JSX.Element;
export default InitialModalHandler;
//# sourceMappingURL=InitialModalHandler.d.ts.map