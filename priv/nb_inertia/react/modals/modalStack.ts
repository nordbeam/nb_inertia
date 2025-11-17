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

import React, { createContext, useContext, useState, useCallback, useRef } from 'react';
import type {
  ModalConfig,
  ModalEventType,
  ModalEventHandler,
  ModalInstance,
  ModalStackContextValue,
} from './types';

// Re-export types for convenience
export type {
  ModalConfig,
  ModalEventType,
  ModalEventHandler,
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
}) => {
  const [modals, setModals] = useState<ModalInstance[]>([]);
  const nextIdRef = useRef(0);

  /**
   * Push a new modal onto the stack
   */
  const pushModal = useCallback(
    (modalData: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>) => {
      const id = `modal-${nextIdRef.current++}`;
      const index = modals.length;

      const modal: ModalInstance = {
        ...modalData,
        id,
        index,
        eventHandlers: new Map(),
      };

      setModals((prev) => {
        const newModals = [...prev, modal];
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });

      return id;
    },
    [modals.length, onStackChange]
  );

  /**
   * Remove a modal from the stack by ID
   */
  const popModal = useCallback(
    (id: string) => {
      setModals((prev) => {
        const newModals = prev.filter((m) => m.id !== id);
        if (onStackChange) {
          onStackChange(newModals);
        }
        return newModals;
      });
    },
    [onStackChange]
  );

  /**
   * Clear all modals from the stack
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
   * Add an event listener to a modal
   */
  const addEventListener = useCallback((id: string, event: ModalEventType, handler: ModalEventHandler) => {
    setModals((prev) =>
      prev.map((modal) => {
        if (modal.id === id) {
          const handlers = modal.eventHandlers.get(event) || new Set();
          handlers.add(handler);
          modal.eventHandlers.set(event, handlers);
        }
        return modal;
      })
    );
  }, []);

  /**
   * Remove an event listener from a modal
   */
  const removeEventListener = useCallback(
    (id: string, event: ModalEventType, handler: ModalEventHandler) => {
      setModals((prev) =>
        prev.map((modal) => {
          if (modal.id === id) {
            const handlers = modal.eventHandlers.get(event);
            if (handlers) {
              handlers.delete(handler);
            }
          }
          return modal;
        })
      );
    },
    []
  );

  /**
   * Emit an event for a modal
   */
  const emitEvent = useCallback(
    async (id: string, event: ModalEventType): Promise<boolean> => {
      const modal = modals.find((m) => m.id === id);
      if (!modal) return true;

      const handlers = modal.eventHandlers.get(event);
      if (!handlers || handlers.size === 0) return true;

      // Execute all handlers
      for (const handler of handlers) {
        try {
          const result = await handler(modal);
          // If any handler returns false, cancel the event
          if (result === false) {
            return false;
          }
        } catch (error) {
          console.error(`Error in modal event handler (${event}):`, error);
          // Continue with other handlers even if one fails
        }
      }

      return true;
    },
    [modals]
  );

  const value: ModalStackContextValue = {
    modals,
    pushModal,
    popModal,
    clearModals,
    getModal,
    addEventListener,
    removeEventListener,
    emitEvent,
  };

  return <ModalStackContext.Provider value={value}>{children}</ModalStackContext.Provider>;
};

export default ModalStackProvider;
