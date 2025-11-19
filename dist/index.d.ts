import { default as default_2 } from 'react';

/**
 * CloseButton - Accessible close button for modals
 *
 * Wraps Radix UI Dialog.Close with a styled close icon button.
 * Features:
 * - Accessible with proper ARIA labels
 * - Keyboard navigation support (Tab, Enter, Space)
 * - ESC key handled automatically by Radix Dialog
 * - Configurable position, size, and colors
 * - Focus ring for keyboard users
 *
 * @example Basic usage
 * ```tsx
 * <CloseButton onClose={handleClose} />
 * ```
 *
 * @example Custom position and size
 * ```tsx
 * <CloseButton
 *   position="top-left"
 *   size="lg"
 *   onClose={handleClose}
 * />
 * ```
 *
 * @example Custom colors
 * ```tsx
 * <CloseButton
 *   colorClasses="text-red-400 hover:text-red-600"
 *   onClose={handleClose}
 * />
 * ```
 *
 * @example Custom positioning
 * ```tsx
 * <CloseButton
 *   position="custom"
 *   className="bottom-4 right-4"
 *   onClose={handleClose}
 * />
 * ```
 */
export declare const CloseButton: default_2.FC<CloseButtonProps>;

/**
 * Props for CloseButton component
 */
export declare interface CloseButtonProps {
    /**
     * Close handler callback
     */
    onClose?: () => void;
    /**
     * Additional CSS classes
     */
    className?: string;
    /**
     * Position of the close button
     * @default 'top-right'
     */
    position?: 'top-right' | 'top-left' | 'custom';
    /**
     * Size of the button
     * @default 'md'
     */
    size?: 'sm' | 'md' | 'lg';
    /**
     * Icon color classes
     * @default 'text-gray-400 hover:text-gray-600'
     */
    colorClasses?: string;
    /**
     * Accessible label
     * @default 'Close'
     */
    ariaLabel?: string;
}

/**
 * Default modal configuration
 *
 * These are the default values used when configuration options are not specified.
 */
export declare const DEFAULT_MODAL_CONFIG: Required<ModalConfig>;

/**
 * HeadlessModal - Core modal state management
 *
 * This component provides the foundational modal logic without any UI:
 * - Modal stack integration
 * - Event system (close, success, blur, focus, beforeClose)
 * - Lifecycle management
 * - Keyboard handling (ESC to close)
 * - Focus trap
 *
 * Use this as a base for building styled modal components.
 */
export declare const HeadlessModal: default_2.FC<HeadlessModalProps>;

/**
 * Props for HeadlessModal component
 */
export declare interface HeadlessModalProps {
    /**
     * Unique identifier for this modal
     */
    id?: string;
    /**
     * Modal component to render
     */
    component: default_2.ComponentType<any>;
    /**
     * Props to pass to the modal component
     */
    componentProps?: Record<string, any>;
    /**
     * Modal configuration
     */
    config?: ModalConfig;
    /**
     * Base URL for the modal (used for navigation)
     */
    baseUrl: string;
    /**
     * Whether the modal is currently open
     */
    open?: boolean;
    /**
     * Callback when the modal is requested to close
     */
    onClose?: () => void;
    /**
     * Callback when the modal successfully closes
     */
    onSuccess?: () => void;
    /**
     * Children to render (for render prop pattern)
     */
    children?: (modal: ModalInstance, close: () => void) => default_2.ReactNode;
}

/**
 * Merge user config with defaults
 *
 * @param config - User-provided configuration
 * @returns Merged configuration with defaults
 */
export declare function mergeModalConfig(config?: ModalConfig): Required<ModalConfig>;

/**
 * Modal - Styled modal component using Radix UI Dialog
 *
 * This component wraps HeadlessModal with a styled UI layer using Radix UI Dialog primitives.
 * It supports:
 * - Configurable size and position
 * - Modal and slideover variants
 * - Stacked modals with proper z-indexing
 * - Custom styling through className and config
 * - Close button (optional, via children)
 * - Backdrop rendering
 *
 * @example Basic modal
 * ```tsx
 * <Modal
 *   component={UserForm}
 *   componentProps={{ userId: 1 }}
 *   baseUrl="/users"
 *   config={{
 *     size: 'lg',
 *     position: 'center',
 *     closeButton: true
 *   }}
 * >
 *   {(close) => (
 *     <>
 *       <h2>User Form</h2>
 *       <UserFormContent />
 *       <button onClick={close}>Close</button>
 *     </>
 *   )}
 * </Modal>
 * ```
 *
 * @example Slideover variant
 * ```tsx
 * <Modal
 *   component={UserEdit}
 *   componentProps={{ user }}
 *   baseUrl="/users"
 *   config={{
 *     slideover: true,
 *     position: 'right',
 *     size: 'lg'
 *   }}
 * >
 *   {(close) => <EditUserForm onClose={close} />}
 * </Modal>
 * ```
 */
export declare const Modal: default_2.FC<ModalProps>;

/**
 * Configuration for a modal instance
 *
 * This interface defines all available configuration options for modals and slideovers.
 * All fields are optional with sensible defaults.
 */
export declare interface ModalConfig {
    /**
     * Size of the modal
     * @default 'md'
     *
     * Presets: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full'
     * Custom: Any valid CSS class string (e.g., 'max-w-4xl')
     */
    size?: ModalSize;
    /**
     * Position of the modal on screen
     * @default 'center'
     *
     * Presets: 'center' | 'top' | 'bottom' | 'left' | 'right'
     * Custom: Any valid CSS class string
     */
    position?: ModalPosition;
    /**
     * Whether this is a slideover (slides in from side) instead of a modal
     * @default false
     */
    slideover?: boolean;
    /**
     * Show a close button in the top-right corner
     * @default true
     */
    closeButton?: boolean;
    /**
     * Require explicit close (disables ESC key and backdrop click)
     * @default false
     */
    closeExplicitly?: boolean;
    /**
     * Custom max-width CSS value
     * @example '800px', '50rem'
     */
    maxWidth?: string;
    /**
     * Custom padding classes for modal content
     * @default 'p-6'
     * @example 'p-8', 'px-4 py-6'
     */
    paddingClasses?: string;
    /**
     * Custom panel classes for the modal container
     * @default 'bg-white rounded-lg shadow-xl'
     * @example 'bg-gray-900 text-white rounded-xl'
     */
    panelClasses?: string;
    /**
     * Custom backdrop classes for the overlay
     * @default 'bg-black/50'
     * @example 'bg-gray-900/75', 'backdrop-blur-sm'
     */
    backdropClasses?: string;
}

/**
 * ModalContent - Styled content wrapper for modals
 *
 * Provides a consistent, accessible modal content container with:
 * - Responsive sizing (sm, md, lg, xl, 2xl, 3xl, 4xl, 5xl, full)
 * - Flexible positioning (center, top, bottom, left, right)
 * - Smooth transitions and animations
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * This component handles the visual presentation of modal content.
 * Use Modal component for full modal functionality with state management.
 *
 * @example Basic usage
 * ```tsx
 * <ModalContent config={{ size: 'md', position: 'center' }}>
 *   <h2>Modal Title</h2>
 *   <p>Modal content</p>
 * </ModalContent>
 * ```
 *
 * @example Custom styling
 * ```tsx
 * <ModalContent
 *   config={{
 *     size: 'lg',
 *     panelClasses: 'bg-gray-900 text-white',
 *     paddingClasses: 'p-8'
 *   }}
 * >
 *   <YourContent />
 * </ModalContent>
 * ```
 *
 * @example With custom max-width
 * ```tsx
 * <ModalContent config={{ maxWidth: '800px' }}>
 *   <WideContent />
 * </ModalContent>
 * ```
 */
export declare const ModalContent: default_2.ForwardRefExoticComponent<ModalContentProps & default_2.RefAttributes<HTMLDivElement>>;

/**
 * Props for ModalContent component
 */
export declare interface ModalContentProps {
    /**
     * Content to render inside the modal
     */
    children: default_2.ReactNode;
    /**
     * Modal configuration (size, position, styling)
     */
    config?: ModalConfig;
    /**
     * Additional CSS classes
     */
    className?: string;
    /**
     * Z-index for stacking
     */
    zIndex?: number;
    /**
     * Close handler
     */
    onClose?: () => void;
}

/**
 * Modal event handler function
 *
 * @param modal - The modal instance that emitted the event
 * @returns void, boolean, or Promise<void | boolean>
 *          - void/undefined: Event continues normally
 *          - true: Event continues (explicit confirmation)
 *          - false: Event is canceled (only for beforeClose)
 */
export declare type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;

/**
 * Modal event types
 *
 * Events that can be emitted by modal instances:
 * - close: Modal is closing (can be canceled via beforeClose)
 * - success: Modal closed successfully with a success action
 * - blur: Modal lost focus (another modal opened on top)
 * - focus: Modal gained focus (became the top modal)
 * - beforeClose: About to close (return false to cancel)
 */
export declare type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';

/**
 * Represents a modal instance in the stack
 *
 * This is the internal representation of a modal managed by the modal stack.
 * It contains all the information needed to render and manage the modal.
 */
export declare interface ModalInstance {
    /**
     * Unique identifier for this modal
     * @example 'modal-0', 'modal-1'
     */
    id: string;
    /**
     * The React component to render inside the modal
     */
    component: default_2.ComponentType<any>;
    /**
     * Props to pass to the component
     */
    props: Record<string, any>;
    /**
     * Modal configuration (size, position, etc.)
     */
    config: ModalConfig;
    /**
     * Base URL for the modal
     *
     * When the modal closes, the browser navigates to this URL.
     * This represents the "background" page that the modal overlays.
     */
    baseUrl: string;
    /**
     * Index in the modal stack
     *
     * 0 = bottom (first modal), higher numbers = on top.
     * Used for z-indexing when multiple modals are stacked.
     */
    index: number;
    /* Excluded from this release type: eventHandlers */
}

/**
 * ModalLink - Link component that opens pages in modals
 *
 * When clicked, this component fetches the target page and displays it in a modal
 * instead of navigating to it. The modal integrates with the modal stack and
 * supports all modal configuration options.
 *
 * Features:
 * - Accepts both string URLs and RouteResult objects
 * - Shows loading state during fetch
 * - Configurable modal appearance via modalConfig
 * - Prevents default navigation behavior
 * - Maintains browser history integration
 *
 * @example
 * ```tsx
 * import { ModalLink } from '@/modals/ModalLink';
 * import { user_path, edit_user_path } from '@/routes';
 *
 * // Basic usage
 * <ModalLink href={user_path(1)}>View User</ModalLink>
 *
 * // With RouteResult
 * <ModalLink href={edit_user_path(1)}>Edit User</ModalLink>
 *
 * // With custom modal config
 * <ModalLink
 *   href={user_path(1)}
 *   modalConfig={{
 *     size: 'lg',
 *     position: 'center',
 *     closeButton: true
 *   }}
 * >
 *   View Details
 * </ModalLink>
 *
 * // Slideover variant
 * <ModalLink
 *   href={edit_user_path(1)}
 *   modalConfig={{
 *     slideover: true,
 *     position: 'right'
 *   }}
 * >
 *   Edit
 * </ModalLink>
 * ```
 */
export declare const ModalLink: default_2.FC<ModalLinkProps>;

/**
 * Props for the ModalLink component
 */
export declare interface ModalLinkProps extends Omit<default_2.AnchorHTMLAttributes<HTMLAnchorElement>, 'href'> {
    /**
     * The URL or RouteResult to navigate to
     *
     * Can be a plain string URL or a RouteResult object from nb_routes rich mode.
     */
    href: string | RouteResult;
    /**
     * Optional modal configuration
     *
     * Configure the modal appearance and behavior when opened.
     */
    modalConfig?: ModalConfig;
    /**
     * Base URL for the modal
     *
     * When the modal closes, the browser will navigate to this URL.
     * If not provided, uses the current URL.
     */
    baseUrl?: string;
    /**
     * HTTP method to use for the request
     *
     * Defaults to 'get'. Can be overridden if href is a string.
     * When href is a RouteResult, the method from the route is used unless explicitly overridden.
     */
    method?: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
    /**
     * Data to send with the request (for POST/PUT/PATCH/DELETE)
     */
    data?: Record<string, any>;
    /**
     * Callback when the link is clicked
     */
    onClick?: (e: default_2.MouseEvent<HTMLAnchorElement>) => void;
    /**
     * Children to render
     */
    children?: default_2.ReactNode;
}

/**
 * Modal position presets and custom positions
 */
export declare type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Props for the Modal component
 */
export declare interface ModalProps extends Omit<HeadlessModalProps, 'children'> {
    /**
     * Children can be a render function or React nodes
     */
    children?: default_2.ReactNode | ((close: () => void) => default_2.ReactNode);
    /**
     * Custom class names for styling
     */
    className?: string;
}

/**
 * Modal size presets and custom sizes
 */
export declare type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

/**
 * Modal stack manager context value
 *
 * This is the API provided by ModalStackProvider to manage modals.
 */
export declare interface ModalStackContextValue {
    /**
     * Array of currently active modals (bottom to top)
     */
    modals: ModalInstance[];
    /**
     * Push a new modal onto the stack
     *
     * @param modal - Modal data without id, index, and eventHandlers (auto-generated)
     * @returns The ID of the newly created modal
     *
     * @example
     * ```tsx
     * const id = pushModal({
     *   component: UserProfile,
     *   props: { userId: 1 },
     *   config: { size: 'lg' },
     *   baseUrl: '/users'
     * });
     * ```
     */
    pushModal: (modal: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>) => string;
    /**
     * Remove a modal from the stack by ID
     *
     * @param id - ID of the modal to remove
     *
     * @example
     * ```tsx
     * popModal('modal-0');
     * ```
     */
    popModal: (id: string) => void;
    /**
     * Clear all modals from the stack
     *
     * @example
     * ```tsx
     * clearModals(); // Close all open modals
     * ```
     */
    clearModals: () => void;
    /**
     * Get a modal instance by ID
     *
     * @param id - ID of the modal to find
     * @returns The modal instance or undefined if not found
     *
     * @example
     * ```tsx
     * const modal = getModal('modal-0');
     * if (modal) {
     *   console.log('Modal config:', modal.config);
     * }
     * ```
     */
    getModal: (id: string) => ModalInstance | undefined;
    /**
     * Register an event listener for a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to listen for
     * @param handler - Event handler function
     *
     * @example
     * ```tsx
     * addEventListener('modal-0', 'beforeClose', async (modal) => {
     *   const confirmed = await confirm('Close modal?');
     *   return confirmed; // Return false to cancel close
     * });
     * ```
     */
    addEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
    /**
     * Remove an event listener from a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to remove handler for
     * @param handler - Event handler function to remove
     *
     * @example
     * ```tsx
     * removeEventListener('modal-0', 'close', myHandler);
     * ```
     */
    removeEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
    /**
     * Emit an event for a modal
     *
     * @param id - ID of the modal
     * @param event - Event type to emit
     * @returns Promise resolving to true if event should continue, false if canceled
     *
     * @example
     * ```tsx
     * const shouldClose = await emitEvent('modal-0', 'beforeClose');
     * if (shouldClose) {
     *   // Proceed with close
     * }
     * ```
     */
    emitEvent: (id: string, event: ModalEventType) => Promise<boolean>;
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
export declare const ModalStackProvider: default_2.FC<ModalStackProviderProps>;

/**
 * Props for ModalStackProvider
 */
declare interface ModalStackProviderProps {
    /**
     * Child components that can access the modal stack
     */
    children: default_2.ReactNode;
    /**
     * Optional callback when modal stack changes
     */
    onStackChange?: (modals: ModalInstance[]) => void;
}

/**
 * NbInertia Enhanced Router for React
 *
 * Provides enhanced Inertia.js router that accepts both string URLs and RouteResult objects
 * from nb_routes rich mode. Maintains full backward compatibility with standard Inertia usage.
 *
 * @example
 * import { router } from '@/nb_inertia/router';
 * import { post_path, update_post_path } from '@/routes';
 *
 * // Use with RouteResult objects
 * router.visit(post_path(1));                    // Automatically uses GET
 * router.visit(update_post_path.patch(1));       // Automatically uses PATCH
 *
 * // Still works with plain strings
 * router.visit('/posts/1');
 * router.get('/posts/1');
 */
/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing the router to automatically use the correct HTTP method.
 */
declare type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};

/**
 * SlideoverContent - Styled content wrapper for slideover panels
 *
 * Provides a sliding panel that appears from the side of the screen with:
 * - Smooth slide-in transitions from any direction (left, right, top, bottom)
 * - Responsive sizing (sm, md, lg, xl, 2xl, full)
 * - Vertical scrolling for overflow content
 * - Accessibility attributes (role, aria-modal)
 * - Customizable styling via config
 *
 * Slideovers are ideal for:
 * - Forms and edit panels
 * - Navigation menus
 * - Filters and settings
 * - Secondary content that doesn't need full page focus
 *
 * @example Basic usage
 * ```tsx
 * <SlideoverContent config={{ position: 'right', size: 'md' }}>
 *   <h2>Edit User</h2>
 *   <form>...</form>
 * </SlideoverContent>
 * ```
 *
 * @example Left side navigation
 * ```tsx
 * <SlideoverContent config={{ position: 'left', size: 'sm' }}>
 *   <nav>
 *     <ul>...</ul>
 *   </nav>
 * </SlideoverContent>
 * ```
 *
 * @example Full width top banner
 * ```tsx
 * <SlideoverContent config={{ position: 'top', size: 'full' }}>
 *   <div className="h-48">
 *     <p>Notification banner</p>
 *   </div>
 * </SlideoverContent>
 * ```
 *
 * @example Custom styling
 * ```tsx
 * <SlideoverContent
 *   config={{
 *     position: 'right',
 *     panelClasses: 'bg-gray-900 text-white',
 *     paddingClasses: 'p-8'
 *   }}
 * >
 *   <DarkModeContent />
 * </SlideoverContent>
 * ```
 */
export declare const SlideoverContent: default_2.ForwardRefExoticComponent<SlideoverContentProps & default_2.RefAttributes<HTMLDivElement>>;

/**
 * Props for SlideoverContent component
 */
export declare interface SlideoverContentProps {
    /**
     * Content to render inside the slideover
     */
    children: default_2.ReactNode;
    /**
     * Modal/slideover configuration
     */
    config?: ModalConfig;
    /**
     * Additional CSS classes
     */
    className?: string;
    /**
     * Z-index for stacking
     */
    zIndex?: number;
    /**
     * Close handler
     */
    onClose?: () => void;
}

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

export { }
