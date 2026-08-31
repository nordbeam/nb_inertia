/**
 * Modal Stack Manager
 *
 * Provides centralized state management for modal instances with support for:
 * - Stacked modals with proper z-indexing
 * - Event system (close, success, blur, focus, beforeClose)
 * - Nested modal management
 * - Event emitter for stack changes
 *
 * @example
 * ```tsx
 * import { ModalStackProvider, useModalStack } from './modalStack';
 *
 * // Wrap your app with ModalStackProvider
 * function App() {
 *   return (
 *     <ModalStackProvider>
 *       <YourApp />
 *     </ModalStackProvider>
 *   );
 * }
 *
 * // Use modal stack in components
 * function MyComponent() {
 *   const { pushModal, popModal, modals } = useModalStack();
 *
 *   const openModal = () => {
 *     pushModal({
 *       component: MyModalComponent,
 *       props: { userId: 1 },
 *       config: { size: 'lg' },
 *       baseUrl: '/users'
 *     });
 *   };
 *
 *   return <button onClick={openModal}>Open Modal</button>;
 * }
 * ```
 */

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useRef,
  useEffect,
} from "react";
import type {
  CacheForOption,
  PrefetchOptions,
  VisitOptions,
} from "@inertiajs/core";
import type { Method } from "@inertiajs/core";
import { router } from "@inertiajs/react";
import { routerPrefetch } from "../../shared/routerCompat";
import { isRouteResult, type RouteResult } from "../../shared/types";
import type {
  ModalInstance,
  ModalPageMetadata,
  ModalVisitOptions,
  ModalPrefetchOptions,
  ModalStackContextValue,
  PrefetchedModal,
} from "./types";
import {
  mergeModalHeaders,
  registerModalRequestContext,
  unregisterModalRequestContext,
} from "./requestContext";

/**
 * Inertia Page object structure for modal context
 */
export interface ModalPageObject {
  component: string;
  props: Record<string, any>;
  url: string;
  baseUrl?: string;
  returnUrl?: string;
  version?: string | number | null;
  flash?: Record<string, unknown>;
  scrollRegions?: Array<{ top: number; left: number }>;
  rememberedState?: Record<string, unknown>;
  clearHistory?: boolean;
  encryptHistory?: boolean;
  preserveFragment?: boolean;
  deferredProps?: ModalPageMetadata["deferredProps"];
  initialDeferredProps?: ModalPageMetadata["initialDeferredProps"];
  rescuedProps: string[];
  mergeProps?: string[];
  prependProps?: string[];
  deepMergeProps?: string[];
  matchPropsOn?: string[];
  sharedProps?: string[];
  scrollProps?: ModalPageMetadata["scrollProps"];
  onceProps?: ModalPageMetadata["onceProps"];
  optimisticUpdatedAt?: ModalPageMetadata["optimisticUpdatedAt"];
}

/**
 * Context for providing modal page data
 * This allows usePage() to work correctly inside modals
 */
const ModalPageContext = createContext<ModalPageObject | null>(null);
ModalPageContext.displayName = "NbInertiaModalPageContext";

/**
 * Hook to check if we're inside a modal context
 * @returns true if component is rendered inside a modal
 */
export function useIsInModal(): boolean {
  return useContext(ModalPageContext) !== null;
}

/**
 * Hook to get the modal's page object
 * Returns null if not in a modal context
 */
export function useModalPageContext(): ModalPageObject | null {
  return useContext(ModalPageContext);
}

/**
 * Provider component that wraps modal content with page context
 * This should be used by modal renderers to provide page data to modal content
 */
export interface ModalPageProviderProps {
  component: string;
  props: Record<string, any>;
  url: string;
  baseUrl?: string;
  returnUrl?: string;
  pageMetadata?: ModalPageMetadata;
  children: React.ReactNode;
}

export const ModalPageProvider: React.FC<ModalPageProviderProps> = ({
  component,
  props,
  url,
  baseUrl,
  returnUrl,
  pageMetadata,
  children,
}) => {
  const contextIdRef = React.useRef(Symbol("nb-inertia-modal-request-context"));
  const page: ModalPageObject = React.useMemo(
    () => ({
      component,
      props,
      url,
      baseUrl,
      returnUrl,
      version:
        pageMetadata?.version === undefined ? "1.0" : pageMetadata.version,
      flash: pageMetadata?.flash ?? {},
      scrollRegions: pageMetadata?.scrollRegions ?? [],
      rememberedState: pageMetadata?.rememberedState ?? {},
      clearHistory: pageMetadata?.clearHistory ?? false,
      encryptHistory: pageMetadata?.encryptHistory ?? false,
      preserveFragment: pageMetadata?.preserveFragment ?? false,
      deferredProps: pageMetadata?.deferredProps,
      initialDeferredProps: pageMetadata?.initialDeferredProps,
      rescuedProps: pageMetadata?.rescuedProps ?? [],
      mergeProps: pageMetadata?.mergeProps,
      prependProps: pageMetadata?.prependProps,
      deepMergeProps: pageMetadata?.deepMergeProps,
      matchPropsOn: pageMetadata?.matchPropsOn,
      sharedProps: pageMetadata?.sharedProps,
      scrollProps: pageMetadata?.scrollProps,
      onceProps: pageMetadata?.onceProps,
      optimisticUpdatedAt: pageMetadata?.optimisticUpdatedAt,
    }),
    [component, props, url, baseUrl, returnUrl, pageMetadata],
  );

  useEffect(() => {
    registerModalRequestContext(contextIdRef.current, {
      url,
      baseUrl,
      returnUrl,
    });

    return () => {
      unregisterModalRequestContext(contextIdRef.current);
    };
  }, [url, baseUrl, returnUrl]);

  return (
    <ModalPageContext.Provider value={page}>
      {children}
    </ModalPageContext.Provider>
  );
};

// Re-export types for convenience
export type {
  ModalConfig,
  ModalInstance,
  ModalStackContextValue,
} from "./types";

/**
 * Modal stack context
 */
const ModalStackContext = createContext<ModalStackContextValue | null>(null);

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
export const useModalStack = (): ModalStackContextValue => {
  const context = useContext(ModalStackContext);
  if (!context) {
    throw new Error("useModalStack must be used within a ModalStackProvider");
  }
  return context;
};

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
export const useModal = (): ModalInstance | null => {
  const { modals } = useModalStack();
  // Return the top modal (last in the stack)
  return modals.length > 0 ? modals[modals.length - 1] : null;
};

/**
 * Function type for resolving component names to React components
 */
export type ResolveComponentFn = (
  name: string,
) => Promise<React.ComponentType<any>>;

function getVisitTarget(href: string | RouteResult, method?: Method) {
  const url = isRouteResult(href) ? href.url : href;
  const requestMethod =
    (isRouteResult(href) && !method ? href.method : method) || "get";

  return { url, method: requestMethod };
}

const DEFAULT_PREFETCH_CACHE_FOR = 30_000;

/** Match Inertia's cache duration forms for the local component/data cache. */
function cacheForToMilliseconds(
  cacheFor?: CacheForOption | CacheForOption[],
): number {
  if (Array.isArray(cacheFor) && cacheFor.length === 0) return 0;

  const value = Array.isArray(cacheFor)
    ? cacheFor[cacheFor.length - 1]
    : cacheFor;

  if (value === undefined) return DEFAULT_PREFETCH_CACHE_FOR;
  if (typeof value === "number") return value;

  const match = String(value)
    .trim()
    .match(/^(-?\d+(?:\.\d+)?)(ms|s|m|h|d)$/i);
  if (!match)
    return Number.parseInt(String(value), 10) || DEFAULT_PREFETCH_CACHE_FOR;

  const multipliers: Record<string, number> = {
    ms: 1,
    s: 1_000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000,
  };

  return Number(match[1]) * (multipliers[match[2].toLowerCase()] ?? 1);
}

/**
 * Props for ModalStackProvider
 */
export interface ModalStackProviderProps {
  /**
   * Child components that can access the modal stack
   */
  children: React.ReactNode;

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
export const ModalStackProvider: React.FC<ModalStackProviderProps> = ({
  children,
  onStackChange,
  resolveComponent,
}) => {
  const [modals, setModals] = useState<ModalInstance[]>([]);
  const nextIdRef = useRef(0);

  // Cache for prefetched modal data (keyed by URL)
  const prefetchCacheRef = useRef<Map<string, PrefetchedModal>>(new Map());
  // Cache for preloaded components (keyed by component name)
  const componentCacheRef = useRef<Map<string, React.ComponentType<any>>>(
    new Map(),
  );
  // Track in-progress prefetches to avoid duplicates
  const prefetchingRef = useRef<Set<string>>(new Set());
  // Keep the exact request options alongside assembled modal data. Inertia's
  // cache is keyed by visit options, so checking it here also makes
  // flush/flushByCacheTags invalidate the component/data cache.
  const prefetchRequestOptionsRef = useRef<
    Map<
      string,
      {
        visitOptions: VisitOptions;
        cacheFor?: CacheForOption | CacheForOption[];
        cacheTags?: string | string[];
      }
    >
  >(new Map());

  /**
   * Push a new modal onto the stack.
   *
   * Returns the modal ID, or empty string if a modal with the same URL already exists.
   *
   * Note: Duplicate prevention is URL-based. Two different components at the same
   * URL cannot both be open simultaneously. This is by design since the URL
   * represents the modal's identity in the browser history.
   */
  const pushModal = useCallback(
    (modalData: Omit<ModalInstance, "id">) => {
      const id = `modal-${nextIdRef.current++}`;

      const modal: ModalInstance = {
        ...modalData,
        id,
      };

      let didPush = false;
      setModals((prev) => {
        // Check if a modal with this URL already exists (prevent duplicates)
        const existingModal = prev.find((m) => m.url === modalData.url);
        if (existingModal) {
          return prev; // Don't add duplicate
        }

        didPush = true;
        const newModals = [...prev, modal];
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });

      return didPush ? id : "";
    },
    [onStackChange],
  );

  /**
   * Remove a modal from the stack by ID
   * Calls the modal's onClose callback after removing it from the stack
   */
  const popModal = useCallback(
    (id: string) => {
      // Use ref-like object to capture callback from inside setModals
      // This avoids stale closure issues where `modals` in the outer scope is outdated
      const callbackRef: { current: (() => void) | null } = { current: null };

      // Remove from stack and capture the callback
      setModals((prev) => {
        // Find the modal in the CURRENT state (prev), not the closure's `modals`
        const modal = prev.find((m) => m.id === id);
        callbackRef.current = modal?.onClose || null;

        const newModals = prev.filter((m) => m.id !== id);
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });

      // Call onClose AFTER state update is scheduled (outside the updater)
      // Use setTimeout to ensure the modal is removed from DOM first
      // Note: setModals callback runs synchronously, so callbackRef.current is set
      setTimeout(() => {
        if (callbackRef.current) {
          try {
            callbackRef.current();
          } catch (error) {
            console.error("Error in modal onClose callback:", error);
          }
        }
      }, 0);
    },
    [onStackChange],
  );

  /**
   * Clear all modals from the stack.
   *
   * By default, does NOT call onClose callbacks (intentional for navigation
   * scenarios where we're already going somewhere else).
   *
   * @param options.fireOnClose - If true, calls each modal's onClose callback.
   *   Use this when clearing modals programmatically outside of navigation.
   */
  const clearModals = useCallback(
    (options?: { fireOnClose?: boolean }) => {
      if (options?.fireOnClose) {
        setModals((prev) => {
          // Collect callbacks before clearing
          const callbacks = prev
            .map((m) => m.onClose)
            .filter((cb): cb is () => void => typeof cb === "function");

          if (onStackChange) {
            onStackChange([]);
          }

          // Fire callbacks after state update
          setTimeout(() => {
            callbacks.forEach((cb) => {
              try {
                cb();
              } catch (error) {
                console.error("Error in modal onClose callback:", error);
              }
            });
          }, 0);

          return [];
        });
      } else {
        setModals([]);
        if (onStackChange) {
          onStackChange([]);
        }
      }
    },
    [onStackChange],
  );

  /**
   * Get a modal by ID
   */
  const getModal = useCallback(
    (id: string) => {
      return modals.find((m) => m.id === id);
    },
    [modals],
  );

  /**
   * Update an existing modal's properties
   * Used to replace a loading modal with actual content
   */
  const updateModal = useCallback(
    (id: string, updates: Partial<Omit<ModalInstance, "id">>) => {
      setModals((prev) => {
        const newModals = prev.map((modal) =>
          modal.id === id ? { ...modal, ...updates } : modal,
        );
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });
    },
    [onStackChange],
  );

  /**
   * Get prefetched modal data from cache by URL
   */
  const getPrefetchedModal = useCallback(
    (url: string): PrefetchedModal | undefined => {
      const cached = prefetchCacheRef.current.get(url);
      if (!cached) return undefined;

      const maxAge =
        cached.cacheFor === undefined
          ? DEFAULT_PREFETCH_CACHE_FOR
          : cacheForToMilliseconds(cached.cacheFor);
      if (maxAge <= 0 || Date.now() - cached.timestamp > maxAge) {
        prefetchCacheRef.current.delete(url);
        prefetchRequestOptionsRef.current.delete(url);
        return undefined;
      }

      // Keep the local assembled cache in lockstep with Inertia's cache. This
      // handles router.flush(), router.flushAll(), and router.flushByCacheTags()
      // without requiring a second invalidation API in the modal layer.
      if (
        cached.visitOptions &&
        router.getCached(url, cached.visitOptions) === null
      ) {
        prefetchCacheRef.current.delete(url);
        prefetchRequestOptionsRef.current.delete(url);
        return undefined;
      }

      return cached;
    },
    [],
  );

  const visitModal = useCallback(
    (href: string | RouteResult, options: ModalVisitOptions = {}) => {
      const { url, method } = getVisitTarget(href, options.method);
      const {
        modalConfig,
        loadingComponent,
        returnUrl: requestedReturnUrl,
        ...inertiaOptions
      } = options;

      const existingModal = modals.find((modal) => modal.url === url);
      if (existingModal) {
        return;
      }

      const returnUrl =
        requestedReturnUrl ||
        (typeof window !== "undefined" ? window.location.href : "");

      const prefetched = method === "get" ? getPrefetchedModal(url) : undefined;

      if (prefetched) {
        pushModal({
          component: prefetched.component,
          componentName: prefetched.data.component,
          props: prefetched.data.props,
          url: prefetched.data.url,
          config: prefetched.data.config || modalConfig || {},
          baseUrl: prefetched.data.baseUrl,
          returnUrl,
          pageMetadata: prefetched.data.pageMetadata,
          onClose: () => {
            if (returnUrl && typeof window !== "undefined") {
              window.history.replaceState({}, "", returnUrl);
            }
          },
        });

        if (typeof window !== "undefined") {
          window.history.pushState({}, "", prefetched.data.url);
        }

        return;
      }

      pushModal({
        component: () => null,
        componentName: "",
        props: {},
        url,
        config: modalConfig || {},
        baseUrl: "",
        returnUrl,
        loading: true,
        loadingComponent,
      });

      const visitOptions: VisitOptions = {
        ...inertiaOptions,
        method,
        data: options.data ?? {},
        preserveState: options.preserveState ?? true,
        preserveScroll: options.preserveScroll ?? true,
        headers: options.headers,
      };

      router.visit(
        url,
        mergeModalHeaders(visitOptions, { url, baseUrl: returnUrl, returnUrl }),
      );
    },
    [getPrefetchedModal, modals, pushModal],
  );

  /**
   * Prefetch modal data and component for a URL
   * This triggers Inertia's prefetch and then resolves the component
   */
  const prefetchModal = useCallback(
    (url: string, options: ModalPrefetchOptions = {}) => {
      // Skip if already prefetching or cached
      if (prefetchingRef.current.has(url)) return;
      if (prefetchCacheRef.current.has(url)) return;

      prefetchingRef.current.add(url);

    const { cacheFor, cacheTags, preserveState, ...visitOptions } = options;
    const requestOptions: VisitOptions = {
      ...visitOptions,
      preserveState: preserveState ?? true,
    };
    const clearInFlight = () => prefetchingRef.current.delete(url);
    const discardRequest = () => {
      clearInFlight();
      prefetchRequestOptionsRef.current.delete(url);
    };
    const userOnFinish = requestOptions.onFinish;
    const userOnCancel = requestOptions.onCancel;
    const userOnError = requestOptions.onError;
    const userOnHttpException = requestOptions.onHttpException;
    const userOnNetworkError = requestOptions.onNetworkError;

    requestOptions.onFinish = (visit) => {
      clearInFlight();
      userOnFinish?.(visit);
    };
    requestOptions.onCancel = () => {
      discardRequest();
      userOnCancel?.();
    };
    requestOptions.onError = (errors, metadata) => {
      discardRequest();
      userOnError?.(errors, metadata);
    };
    requestOptions.onHttpException = (response) => {
      discardRequest();
      return userOnHttpException?.(response);
    };
    requestOptions.onNetworkError = (error) => {
      discardRequest();
      return userOnNetworkError?.(error);
    };

      // Keep the request identity so a later Inertia cache flush also removes
      // the assembled modal cache.
      prefetchRequestOptionsRef.current.set(url, {
        visitOptions: requestOptions,
        cacheFor,
        cacheTags,
      });

      // Trigger Inertia's prefetch. Do not overwrite Inertia's defaults with
      // explicit `undefined` values: its cache duration parser expects a value.
      const prefetchOptions: Partial<PrefetchOptions> = {};
      if (cacheFor !== undefined) prefetchOptions.cacheFor = cacheFor;
      if (cacheTags !== undefined) prefetchOptions.cacheTags = cacheTags;

    try {
      routerPrefetch(
        url,
        requestOptions,
        Object.keys(prefetchOptions).length > 0 ? prefetchOptions : undefined,
      );
    } catch (error) {
      discardRequest();
      throw error;
    }
    },
    [],
  );

  /**
   * Listen for Inertia prefetch events and preload component modules
   * When a prefetch completes, we:
   * 1. Extract modal data from the response
   * 2. Resolve the component module (triggers dynamic import)
   * 3. Cache both data and component together keyed by URL
   */
  useEffect(() => {
    if (!resolveComponent) return;

    // Listen for prefetch completions
    const unsubscribe = router.on("prefetched", (event: CustomEvent) => {
      // Inertia emits an HttpResponse whose `data` member is the Page. Keep a
      // compatibility fallback for adapters that emit the Page directly.
      const rawResponse = (event.detail as Record<string, unknown>)?.response;
      const rawPage =
        rawResponse && typeof rawResponse === "object" && "data" in rawResponse
          ? (rawResponse as { data?: unknown }).data
          : rawResponse;
      const pageData =
        typeof rawPage === "string"
          ? JSON.parse(rawPage)
          : (rawPage as Record<string, any>);

      const visitUrl = (event.detail as { visit?: { url?: URL } })?.visit?.url;
      const responseUrl = pageData?.url || visitUrl;
      const matchingRequestUrls = [...prefetchingRef.current].filter((candidate) => {
        if (!responseUrl) return false;

        try {
          return new URL(candidate, window.location.href).href === new URL(responseUrl, window.location.href).href;
        } catch {
          return candidate === String(responseUrl);
        }
      });
      const modalData = pageData?.props?._nb_modal;

      if (!modalData?.component) {
        matchingRequestUrls.forEach((requestUrl) => {
          prefetchingRef.current.delete(requestUrl);
          prefetchRequestOptionsRef.current.delete(requestUrl);
        });
        return;
      }

      const componentName = modalData.component;
      const modalUrl = modalData.url || pageData?.url;

      if (!modalUrl) return;

      const request =
        prefetchRequestOptionsRef.current.get(modalUrl) ||
        prefetchRequestOptionsRef.current.get(pageData?.url);
      prefetchingRef.current.delete(modalUrl);
      if (pageData?.url && pageData.url !== modalUrl) {
        prefetchingRef.current.delete(pageData.url);
      }
      matchingRequestUrls.forEach((requestUrl) => prefetchingRef.current.delete(requestUrl));

      // Skip if already fully cached
      if (prefetchCacheRef.current.has(modalUrl)) return;

      // Check if component is already cached
      const cachedComponent = componentCacheRef.current.get(componentName);

      if (cachedComponent) {
        // Component already loaded, just cache the full prefetch
        prefetchCacheRef.current.set(modalUrl, {
          data: {
            component: componentName,
            props: modalData.props || {},
            url: modalUrl,
            baseUrl: modalData.baseUrl || "",
            config: modalData.config,
            pageMetadata: modalData.pageMetadata || pageData,
          },
          component: cachedComponent,
          timestamp: Date.now(),
          cacheFor: request?.cacheFor,
          cacheTags: request?.cacheTags,
          visitOptions: request?.visitOptions,
        });
      } else {
        // Preload the component module (triggers dynamic import)
        resolveComponent(componentName)
          .then((Component) => {
            // Cache the component for reuse
            componentCacheRef.current.set(componentName, Component);

            // Cache the full prefetch data
            prefetchCacheRef.current.set(modalUrl, {
              data: {
                component: componentName,
                props: modalData.props || {},
                url: modalUrl,
                baseUrl: modalData.baseUrl || "",
                config: modalData.config,
                pageMetadata: modalData.pageMetadata || pageData,
              },
              component: Component,
              timestamp: Date.now(),
              cacheFor: request?.cacheFor,
              cacheTags: request?.cacheTags,
              visitOptions: request?.visitOptions,
            });
          })
          .catch((error) => {
            prefetchRequestOptionsRef.current.delete(modalUrl);
            console.warn(
              "[ModalStack] Component preload failed:",
              componentName,
              error,
            );
          });
      }
    });

    return unsubscribe;
  }, [resolveComponent]);

  const value: ModalStackContextValue = {
    modals,
    pushModal,
    popModal,
    clearModals,
    getModal,
    updateModal,
    visitModal,
    resolveComponent,
    prefetchModal: resolveComponent ? prefetchModal : undefined,
    getPrefetchedModal,
  };

  return (
    <ModalStackContext.Provider value={value}>
      {children}
    </ModalStackContext.Provider>
  );
};

export default ModalStackProvider;
