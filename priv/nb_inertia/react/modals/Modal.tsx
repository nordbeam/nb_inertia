import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { HeadlessModal, type HeadlessModalProps } from './HeadlessModal';
import { ModalContent } from './ModalContent';
import { SlideoverContent } from './SlideoverContent';
import { CloseButton } from './CloseButton';
import type { ModalConfig } from './types';

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
 * Get backdrop classes with defaults
 */
function getBackdropClasses(config?: ModalConfig): string {
  const defaults = 'fixed inset-0 bg-black/50';
  return config?.backdropClasses ? `${defaults} ${config.backdropClasses}` : defaults;
}

/**
 * Get z-index based on modal stack index
 */
function getZIndex(index: number): number {
  const baseZIndex = 50;
  return baseZIndex + index;
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
export const Modal: React.FC<ModalProps> = ({
  children,
  className,
  config = {},
  open = true,
  onClose,
  ...headlessProps
}) => {
  const isSlideover = config.slideover || false;
  const showCloseButton = config.closeButton !== false;

  return (
    <HeadlessModal
      {...headlessProps}
      config={config}
      open={open}
      onClose={onClose}
    >
      {(modal, close) => (
        <Dialog.Root open={open} onOpenChange={(isOpen) => !isOpen && close()}>
          <Dialog.Portal>
            {/* Backdrop/Overlay */}
            <Dialog.Overlay
              className={getBackdropClasses(config)}
              style={{ zIndex: getZIndex(modal.index) }}
            />

            {/* Modal or Slideover Content */}
            {isSlideover ? (
              <SlideoverContent
                config={config}
                className={className}
                zIndex={getZIndex(modal.index) + 1}
              >
                {/* Close Button */}
                {showCloseButton && <CloseButton onClose={close} />}

                {/* Content */}
                {typeof children === 'function' ? children(close) : children}
              </SlideoverContent>
            ) : (
              <ModalContent
                config={config}
                className={className}
                zIndex={getZIndex(modal.index) + 1}
              >
                {/* Close Button */}
                {showCloseButton && <CloseButton onClose={close} />}

                {/* Content */}
                {typeof children === 'function' ? children(close) : children}
              </ModalContent>
            )}
          </Dialog.Portal>
        </Dialog.Root>
      )}
    </HeadlessModal>
  );
};

export default Modal;
