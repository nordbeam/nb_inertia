import { default as React } from 'react';
import { HeadlessModalProps } from './HeadlessModal';
/**
 * Props for the Modal component
 */
export interface ModalProps extends Omit<HeadlessModalProps, 'children'> {
    /**
     * Children can be a render function or React nodes
     */
    children?: React.ReactNode | ((close: () => void) => React.ReactNode);
    /**
     * Custom class names for styling
     */
    className?: string;
}
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
export declare const Modal: React.FC<ModalProps>;
export default Modal;
//# sourceMappingURL=Modal.d.ts.map