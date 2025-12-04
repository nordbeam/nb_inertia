/**
 * Check if the modal interceptor has been set up
 */
export declare function isModalInterceptorRegistered(): boolean;

/**
 * Modal Backdrop Preservation via Axios Interceptor
 *
 * When navigating to a modal URL via XHR, this interceptor modifies the
 * response to preserve the current page as the backdrop. It detects the
 * `x-inertia-modal` header and:
 *
 * 1. Keeps the current page's component (instead of swapping to modal component)
 * 2. Merges current page props with modal props (modal props win on conflict)
 *
 * This way, Inertia thinks it's just updating the current page with new props
 * (which include `_nb_modal`), so no page swap occurs. The modal is then
 * rendered by ModalRoot which detects `_nb_modal` in the props.
 *
 * Based on the approach from inertiaui/modal and emargareten/inertia-modal.
 *
 * @example
 * ```tsx
 * // In your app.tsx, before createInertiaApp:
 * import { setupModalInterceptor } from '@nordbeam/nb-inertia/react';
 *
 * setupModalInterceptor();
 *
 * createInertiaApp({
 *   // ... normal setup
 * });
 * ```
 */
/**
 * Sets up the axios interceptor for modal backdrop preservation.
 *
 * Call this once at app startup, before createInertiaApp.
 * This function is SSR-safe and will only register the interceptor on the client.
 *
 * @example
 * ```tsx
 * import { setupModalInterceptor } from '@nordbeam/nb-inertia/react';
 *
 * setupModalInterceptor();
 *
 * createInertiaApp({
 *   resolve: (name) => pages[`./pages/${name}.tsx`](),
 *   setup({ App, el, props }) {
 *     createRoot(el).render(
 *       <ModalStackProvider>
 *         <ModalRoot resolveComponent={...}>
 *           <App {...props} />
 *           <ModalStackRenderer />
 *         </ModalRoot>
 *       </ModalStackProvider>
 *     );
 *   },
 * });
 * ```
 */
declare function setupModalInterceptor(): void;
export default setupModalInterceptor;
export { setupModalInterceptor }

export { }
