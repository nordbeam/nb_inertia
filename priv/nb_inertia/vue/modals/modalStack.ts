/**
 * Modal Stack Manager (Vue Composition API)
 *
 * Provides centralized state management for modal instances using Vue 3 Composition API.
 * This is the Vue equivalent of the React modal stack.
 *
 * @example
 * ```vue
 * <script setup>
 * import { provide } from 'vue';
 * import { createModalStack, MODAL_STACK_KEY } from './modalStack';
 *
 * // In your root component
 * const modalStack = createModalStack();
 * provide(MODAL_STACK_KEY, modalStack);
 * </script>
 * ```
 */

import { ref, readonly, inject, type InjectionKey } from 'vue';
import type {
  ModalConfig,
  ModalEventType,
  ModalEventHandler,
  ModalInstance,
  ModalStackState,
} from './types';

// Re-export types
export type {
  ModalConfig,
  ModalEventType,
  ModalEventHandler,
  ModalInstance,
  ModalStackState,
} from './types';

/**
 * Injection key for modal stack
 */
export const MODAL_STACK_KEY: InjectionKey<ModalStackState> = Symbol('modalStack');

/**
 * Create a modal stack instance
 *
 * This function creates a reactive modal stack that can be provided
 * to the component tree via Vue's provide/inject API.
 *
 * @param onStackChange - Optional callback when modal stack changes
 * @returns Modal stack state object
 *
 * @example
 * ```vue
 * <script setup>
 * import { provide } from 'vue';
 * import { createModalStack, MODAL_STACK_KEY } from './modalStack';
 *
 * const modalStack = createModalStack((modals) => {
 *   console.log('Modal stack changed:', modals.length);
 * });
 *
 * provide(MODAL_STACK_KEY, modalStack);
 * </script>
 * ```
 */
export function createModalStack(
  onStackChange?: (modals: ModalInstance[]) => void
): ModalStackState {
  const modals = ref<ModalInstance[]>([]);
  let nextId = 0;

  /**
   * Push a new modal onto the stack
   */
  function pushModal(modalData: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>): string {
    const id = `modal-${nextId++}`;
    const index = modals.value.length;

    const modal: ModalInstance = {
      ...modalData,
      id,
      index,
      eventHandlers: new Map(),
    };

    modals.value = [...modals.value, modal];

    if (onStackChange) {
      onStackChange(modals.value);
    }

    return id;
  }

  /**
   * Remove a modal from the stack by ID
   */
  function popModal(id: string): void {
    modals.value = modals.value.filter((m) => m.id !== id);

    if (onStackChange) {
      onStackChange(modals.value);
    }
  }

  /**
   * Clear all modals from the stack
   */
  function clearModals(): void {
    modals.value = [];

    if (onStackChange) {
      onStackChange(modals.value);
    }
  }

  /**
   * Get a modal by ID
   */
  function getModal(id: string): ModalInstance | undefined {
    return modals.value.find((m) => m.id === id);
  }

  /**
   * Add an event listener to a modal
   */
  function addEventListener(id: string, event: ModalEventType, handler: ModalEventHandler): void {
    const modal = modals.value.find((m) => m.id === id);
    if (!modal) return;

    const handlers = modal.eventHandlers.get(event) || new Set();
    handlers.add(handler);
    modal.eventHandlers.set(event, handlers);
  }

  /**
   * Remove an event listener from a modal
   */
  function removeEventListener(id: string, event: ModalEventType, handler: ModalEventHandler): void {
    const modal = modals.value.find((m) => m.id === id);
    if (!modal) return;

    const handlers = modal.eventHandlers.get(event);
    if (handlers) {
      handlers.delete(handler);
    }
  }

  /**
   * Emit an event for a modal
   */
  async function emitEvent(id: string, event: ModalEventType): Promise<boolean> {
    const modal = modals.value.find((m) => m.id === id);
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
        // Continue with other handlers
      }
    }

    return true;
  }

  return {
    modals: readonly(modals) as any,
    pushModal,
    popModal,
    clearModals,
    getModal,
    addEventListener,
    removeEventListener,
    emitEvent,
  };
}

/**
 * Use modal stack (must be within a component that has access to the injected stack)
 *
 * @throws Error if used outside of modal stack provider
 * @returns Modal stack state
 *
 * @example
 * ```vue
 * <script setup>
 * import { useModalStack } from './modalStack';
 *
 * const { pushModal, modals } = useModalStack();
 *
 * function openModal() {
 *   pushModal({
 *     component: UserProfile,
 *     props: { userId: 1 },
 *     config: { size: 'lg' },
 *     baseUrl: '/users'
 *   });
 * }
 * </script>
 * ```
 */
export function useModalStack(): ModalStackState {
  const stack = inject<ModalStackState>(MODAL_STACK_KEY);

  if (!stack) {
    throw new Error('useModalStack must be used within a component with modal stack provided');
  }

  return stack;
}

/**
 * Use current modal (returns the topmost modal)
 *
 * @returns The current modal instance or null
 *
 * @example
 * ```vue
 * <script setup>
 * import { useModal } from './modalStack';
 *
 * const modal = useModal();
 * </script>
 *
 * <template>
 *   <div v-if="modal">
 *     <h1>Modal {{ modal.id }}</h1>
 *     <p>Index: {{ modal.index }}</p>
 *   </div>
 * </template>
 * ```
 */
export function useModal(): ModalInstance | null {
  const { modals } = useModalStack();
  return modals.length > 0 ? modals[modals.length - 1] : null;
}
