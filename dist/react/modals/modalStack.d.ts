import { default as React } from 'react';
import { ModalInstance, ModalStackContextValue } from './types';
export type { ModalConfig, ModalEventType, ModalEventHandler, ModalInstance, ModalStackContextValue, } from './types';
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
export declare const useModalStack: () => ModalStackContextValue;
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
export declare const useModal: () => ModalInstance | null;
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
export declare const ModalStackProvider: React.FC<ModalStackProviderProps>;
export default ModalStackProvider;
//# sourceMappingURL=modalStack.d.ts.map