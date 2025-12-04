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

import axios from 'axios';

/**
 * The header sent by the backend to indicate a modal response.
 * Must match NbInertia.Modal.modal_header/0
 */
const MODAL_HEADER = 'x-inertia-modal';

/**
 * Track if the interceptor has been set up to prevent duplicate registration
 */
let interceptorRegistered = false;

/**
 * Get the current Inertia page state.
 * We dynamically import to avoid circular dependencies.
 */
async function getCurrentPage(): Promise<{ component: string; props: Record<string, unknown> } | null> {
  try {
    const { router } = await import('@inertiajs/react');
    // router.page contains the current page state
    if (router.page) {
      return {
        component: router.page.component,
        props: router.page.props as Record<string, unknown>,
      };
    }
  } catch (error) {
    console.error('[nb-inertia] Failed to get current page:', error);
  }
  return null;
}

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
export function setupModalInterceptor(): void {
  // SSR-safe: Only run on client
  if (typeof window === 'undefined') {
    return;
  }

  if (interceptorRegistered) {
    console.warn('[nb-inertia] Modal interceptor already registered, skipping duplicate setup');
    return;
  }

  axios.interceptors.response.use(
    async (response) => {
      // Check if this is a modal response
      const isModalResponse = response.headers[MODAL_HEADER] === 'true';

      if (!isModalResponse) {
        return response;
      }

      // Get current page state
      const currentPage = await getCurrentPage();

      if (!currentPage) {
        // This is expected on direct URL access to a modal - InitialModalHandler will handle it
        console.debug('[nb-inertia] No current page for backdrop preservation (expected on direct URL access)');
        return response;
      }

      // Parse response data if it's a string
      let responseData = response.data;
      if (typeof responseData === 'string') {
        try {
          responseData = JSON.parse(responseData);
        } catch (e) {
          console.error('[nb-inertia] Failed to parse modal response:', e);
          return response;
        }
      }

      // Deep clone current props to avoid mutations
      const currentProps = JSON.parse(JSON.stringify(currentPage.props));

      // Merge props: current page props + modal response props
      // Modal props (including _nb_modal) take precedence
      const mergedProps = {
        ...currentProps,
        ...responseData.props,
      };

      // Modify response to keep current component (preserve backdrop)
      responseData.component = currentPage.component;
      responseData.props = mergedProps;

      // Update response.data
      response.data = responseData;

      return response;
    },
    (error) => {
      // Pass through errors unchanged
      return Promise.reject(error);
    }
  );

  interceptorRegistered = true;
}

/**
 * Check if the modal interceptor has been set up
 */
export function isModalInterceptorRegistered(): boolean {
  return interceptorRegistered;
}

export default setupModalInterceptor;
