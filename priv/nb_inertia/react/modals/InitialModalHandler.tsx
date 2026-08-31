/**
 * InitialModalHandler - Detects initial modal props and handles navigation events
 *
 * This component is independent of React's Inertia page context. Pass the
 * initial page from `createInertiaApp`'s `withApp`/`setup` callback so it can
 * handle direct modal URLs, while navigation events keep it in sync afterward.
 * It handles:
 * 1. Initial page load with _nb_modal prop (direct URL access to modal)
 * 2. Navigation events that include modal data
 *
 * @example
 * ```tsx
 * import { ModalStackProvider, InitialModalHandler, ModalStackRenderer } from '@nordbeam/nb-inertia/react/modals';
 *
 * createInertiaApp({
 *   resolve: resolveComponent,
 *   withApp: (app, { page }) => (
 *     <ModalStackProvider resolveComponent={resolveComponent}>
 *       {app}
 *       <InitialModalHandler
 *         resolveComponent={resolveComponent}
 *         initialPage={page}
 *       />
 *       <ModalStackRenderer />
 *     </ModalStackProvider>
 *   ),
 * });
 * ```
 */

import { useEffect, useRef, useCallback } from "react";
import { router, usePage } from "@inertiajs/react";
import type { Page as InertiaPage } from "@inertiajs/core";
import { useModalStack } from "./modalStack";
import type { ModalConfig, ModalPageMetadata } from "./types";

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
 * Handles initial modal detection and navigation events
 *
 * This component:
 * - Detects `_nb_modal` prop on initial page load (direct URL access)
 * - Listens for Inertia navigation events with modal data
 * - Pushes modals onto the stack via useModalStack
 * - Manages browser history for proper back/forward navigation
 */
function ModalEventHandler({ resolveComponent, initialPage }: InitialModalHandlerProps) {
  const { pushModal, updateModal, clearModals, modals } = useModalStack();
  const isNavigatingRef = useRef(false);
  const initialModalHandledRef = useRef(false);
  const currentModalRef = useRef<ModalOnBase | null>(null);
  // Track URLs that are currently being opened or have been opened (to prevent duplicates)
  const handledUrlsRef = useRef<Set<string>>(new Set());

  /**
   * Creates an onClose handler for a modal that:
   * 1. Clears the currentModalRef so the same modal can be reopened
   * 2. Updates the URL to the return URL (or base URL) using history.replaceState
   *
   * @param modalOnBase - The modal data from the backend
   * @param returnUrl - Optional return URL captured when the modal was opened (includes query params)
   */
  const createOnClose = useCallback((modalOnBase: ModalOnBase, returnUrl?: string) => {
    return () => {
      // Clear the current modal ref so the same modal can be opened again
      currentModalRef.current = null;
      // Allow this URL to be opened again
      handledUrlsRef.current.delete(modalOnBase.url);

      // Update URL when modal is closed
      // We use history.replaceState instead of router.visit because:
      // 1. The backdrop already shows the correct base page content
      // 2. router.visit would trigger a full navigation that races with React re-render
      //
      // Priority: returnUrl (full URL with query params) > baseUrl (path only)
      if (!isNavigatingRef.current && typeof window !== "undefined") {
        const targetUrl = returnUrl || modalOnBase.baseUrl;
        if (targetUrl && window.location.href !== targetUrl) {
          window.history.replaceState({}, "", targetUrl);
        }
      }
    };
  }, []);

  /**
   * Resolves and pushes a modal onto the stack, or updates a loading modal
   */
  const openModal = useCallback(
    (modalOnBase: ModalOnBase, responsePageMetadata?: ModalPageMetadata) => {
      const pageMetadata = responsePageMetadata || modalOnBase.pageMetadata;
      const url = modalOnBase.url;
      const loadingModal = modals.find((m) => m.loading && m.url === url);
      const existingModal = modals.find((m) => !m.loading && m.url === url);

      // Avoid racing duplicate open requests for the same new URL, but allow
      // same-URL navigations to refresh an already mounted modal.
      if (handledUrlsRef.current.has(url) && !loadingModal && !existingModal) {
        return;
      }

      // Mark as handled immediately to prevent race conditions
      handledUrlsRef.current.add(url);

      resolveComponent(modalOnBase.component)
        .then((Component) => {
          if (loadingModal) {
            // Re-check if modal still exists and is still loading
            // (user might have closed it during component resolution)
            const stillLoading = modals.find((m) => m.id === loadingModal.id && m.loading);
            if (!stillLoading) {
              // Modal was closed during resolution - don't update
              handledUrlsRef.current.delete(url);
              return;
            }

            // Preserve the returnUrl from the loading modal (captured by ModalLink)
            const returnUrl = loadingModal.returnUrl;

            // Update the existing loading modal with actual content
            updateModal(loadingModal.id, {
              component: Component,
              componentName: modalOnBase.component,
              props: modalOnBase.props,
              config: modalOnBase.config || {},
              baseUrl: modalOnBase.baseUrl,
              returnUrl, // Preserve the return URL
              pageMetadata,
              onClose: createOnClose(modalOnBase, returnUrl),
              loading: false,
            });
            currentModalRef.current = modalOnBase;
          } else if (existingModal) {
            updateModal(existingModal.id, {
              component: Component,
              componentName: modalOnBase.component,
              props: modalOnBase.props,
              config: modalOnBase.config || {},
              baseUrl: modalOnBase.baseUrl,
              pageMetadata,
              onClose: existingModal.onClose || createOnClose(modalOnBase, existingModal.returnUrl),
            });
            currentModalRef.current = modalOnBase;
          } else {
            // No loading modal found - push new modal (direct URL access case)
            // For direct URL access, there's no return URL - use baseUrl for restoration
            currentModalRef.current = modalOnBase;
            pushModal({
              component: Component,
              componentName: modalOnBase.component,
              props: modalOnBase.props,
              url: modalOnBase.url,
              config: modalOnBase.config || {},
              baseUrl: modalOnBase.baseUrl,
              pageMetadata,
              onClose: createOnClose(modalOnBase),
            });
          }
        })
        .catch((error) => {
          handledUrlsRef.current.delete(url);
          console.error(
            "[InitialModalHandler] Failed to resolve modal component:",
            modalOnBase.component,
            error,
          );
        });
    },
    [resolveComponent, pushModal, updateModal, modals, createOnClose],
  );

  // Handle initial modal from page props (direct URL access)
  useEffect(() => {
    const modalOnBase = (initialPage?.props as Record<string, unknown> | undefined)?._nb_modal as
      | ModalOnBase
      | undefined;

    if (modalOnBase && !initialModalHandledRef.current) {
      initialModalHandledRef.current = true;
      openModal(modalOnBase, initialPage);
    }
  }, []); // Only run once on mount

  // Handle navigation events
  useEffect(() => {
    const unsubscribeStart = router.on("start", () => {
      isNavigatingRef.current = true;
    });

    const unsubscribeFinish = router.on("finish", () => {
      isNavigatingRef.current = false;
    });

    const unsubscribeNavigate = router.on("navigate", (event) => {
      const modalOnBase = (event.detail.page.props as Record<string, unknown>)?._nb_modal as
        | ModalOnBase
        | undefined;

      if (!modalOnBase) {
        // No modal in this navigation - clear all modals and reset tracking
        clearModals();
        currentModalRef.current = null;
        handledUrlsRef.current.clear();
        return;
      }

      openModal(modalOnBase, event.detail.page);
    });

    return () => {
      unsubscribeStart();
      unsubscribeFinish();
      unsubscribeNavigate();
    };
  }, [openModal, clearModals]);

  // This component doesn't render anything
  return null;
}

function ContextInitialModalHandler({
  resolveComponent,
}: Pick<InitialModalHandlerProps, "resolveComponent">) {
  const page = usePage();

  return <ModalEventHandler resolveComponent={resolveComponent} initialPage={page} />;
}

/**
 * Mount the modal event bridge with an explicit initial page (recommended for
 * Inertia v3 `withApp` wrappers) or, for backward compatibility, inside the
 * Inertia component tree where the official `usePage` context is available.
 */
export function InitialModalHandler({ resolveComponent, initialPage }: InitialModalHandlerProps) {
  if (initialPage) {
    return <ModalEventHandler resolveComponent={resolveComponent} initialPage={initialPage} />;
  }

  return <ContextInitialModalHandler resolveComponent={resolveComponent} />;
}

export default InitialModalHandler;
