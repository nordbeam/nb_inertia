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

import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { router } from '@inertiajs/react';
import type {
  ModalConfig,
  ModalInstance,
  ModalStackContextValue,
  PrefetchedModal,
} from './types';

/**
 * Inertia Page object structure for modal context
 */
export interface ModalPageObject {
  component: string;
  props: Record<string, any>;
  url: string;
  version?: string;
  scrollRegions?: Array<{ top: number; left: number }>;
  rememberedState?: Record<string, unknown>;
  clearHistory?: boolean;
  encryptHistory?: boolean;
}

/**
 * Context for providing modal page data
 * This allows usePage() to work correctly inside modals
 */
const ModalPageContext = createContext<ModalPageObject | null>(null);
ModalPageContext.displayName = 'NbInertiaModalPageContext';

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
  children: React.ReactNode;
}

export const ModalPageProvider: React.FC<ModalPageProviderProps> = ({
  component,
  props,
  url,
  children,
}) => {
  const page: ModalPageObject = React.useMemo(
    () => ({
      component,
      props,
      url,
      version: '1.0',
      scrollRegions: [],
      rememberedState: {},
      clearHistory: false,
      encryptHistory: false,
    }),
    [component, props, url]
  );

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
} from './types';

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
    throw new Error('useModalStack must be used within a ModalStackProvider');
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
export type ResolveComponentFn = (name: string) => Promise<React.ComponentType<any>>;

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
  const componentCacheRef = useRef<Map<string, React.ComponentType<any>>>(new Map());
  // Track in-progress prefetches to avoid duplicates
  const prefetchingRef = useRef<Set<string>>(new Set());

  /**
   * Push a new modal onto the stack
   * Returns the modal ID, or empty string if a modal with the same URL already exists
   */
  const pushModal = useCallback(
    (modalData: Omit<ModalInstance, 'id'>) => {
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

      return didPush ? id : '';
    },
    [onStackChange]
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
            console.error('Error in modal onClose callback:', error);
          }
        }
      }, 0);
    },
    [onStackChange]
  );

  /**
   * Clear all modals from the stack
   * Note: Does NOT call onClose callbacks. This is intentional because clearModals
   * is typically called during navigation when we're already going somewhere else.
   * Use popModal if you need onClose callbacks to fire.
   */
  const clearModals = useCallback(() => {
    setModals([]);
    if (onStackChange) {
      onStackChange([]);
    }
  }, [onStackChange]);

  /**
   * Get a modal by ID
   */
  const getModal = useCallback(
    (id: string) => {
      return modals.find((m) => m.id === id);
    },
    [modals]
  );

  /**
   * Update an existing modal's properties
   * Used to replace a loading modal with actual content
   */
  const updateModal = useCallback(
    (id: string, updates: Partial<Omit<ModalInstance, 'id'>>) => {
      setModals((prev) => {
        const newModals = prev.map((modal) =>
          modal.id === id ? { ...modal, ...updates } : modal
        );
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });
    },
    [onStackChange]
  );

  /**
   * Get prefetched modal data from cache by URL
   */
  const getPrefetchedModal = useCallback((url: string): PrefetchedModal | undefined => {
    const cached = prefetchCacheRef.current.get(url);
    if (!cached) return undefined;

    // Check if cache is still valid (default 30 seconds)
    const maxAge = 30000;
    if (Date.now() - cached.timestamp > maxAge) {
      prefetchCacheRef.current.delete(url);
      return undefined;
    }

    return cached;
  }, []);

  /**
   * Prefetch modal data and component for a URL
   * This triggers Inertia's prefetch and then resolves the component
   */
  const prefetchModal = useCallback((url: string, options?: { cacheFor?: number }) => {
    // Skip if already prefetching or cached
    if (prefetchingRef.current.has(url)) return;
    if (prefetchCacheRef.current.has(url)) return;

    prefetchingRef.current.add(url);

    // Trigger Inertia's prefetch
    const prefetchOptions: { cacheFor?: number } = {};
    if (options?.cacheFor !== undefined) prefetchOptions.cacheFor = options.cacheFor;

    (router as any).prefetch?.(url, { preserveState: true }, prefetchOptions);
    prefetchingRef.current.delete(url);
  }, []);

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
    const unsubscribe = router.on('prefetched', (event: any) => {
      // The response may be a JSON string or already parsed object
      const rawResponse = event.detail?.response;
      const pageData = typeof rawResponse === 'string' ? JSON.parse(rawResponse) : rawResponse;

      const modalData = pageData?.props?._nb_modal;
      if (!modalData?.component) return;

      const componentName = modalData.component;
      const modalUrl = modalData.url || pageData?.url;

      if (!modalUrl) return;

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
            baseUrl: modalData.baseUrl || '',
            config: modalData.config,
          },
          component: cachedComponent,
          timestamp: Date.now(),
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
                baseUrl: modalData.baseUrl || '',
                config: modalData.config,
              },
              component: Component,
              timestamp: Date.now(),
            });
          })
          .catch((error) => {
            console.warn('[ModalStack] Component preload failed:', componentName, error);
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
    resolveComponent,
    prefetchModal: resolveComponent ? prefetchModal : undefined,
    getPrefetchedModal,
  };

  return <ModalStackContext.Provider value={value}>{children}</ModalStackContext.Provider>;
};

export default ModalStackProvider;
