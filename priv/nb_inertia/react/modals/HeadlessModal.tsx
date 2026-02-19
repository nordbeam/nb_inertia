/**
 * HeadlessModal - Core modal state management for React
 *
 * Provides foundational modal logic without any UI:
 * - Modal stack integration (register/unregister)
 * - Keyboard handling (ESC to close unless closeExplicitly)
 * - Lifecycle management (open/close callbacks)
 *
 * Use this as a base for building your own styled modal components.
 *
 * @example
 * ```tsx
 * <HeadlessModal
 *   modal={modalInstance}
 *   onClose={() => popModal(modalInstance.id)}
 * >
 *   {({ close }) => (
 *     <div className="my-modal">
 *       <MyModalComponent {...modalInstance.props} close={close} />
 *     </div>
 *   )}
 * </HeadlessModal>
 * ```
 */

import { useEffect, useCallback, useRef } from 'react';
import type { ModalInstance, ModalConfig } from './types';
import { mergeModalConfig } from './types';

export interface HeadlessModalProps {
  /** The modal instance from the stack */
  modal: ModalInstance;

  /** Called when the modal should close */
  onClose: () => void;

  /**
   * Render function receiving a close handler.
   * The close handler triggers onClose after any beforeClose logic.
   */
  children: (context: { close: () => void; config: ModalConfig }) => React.ReactNode;
}

/**
 * HeadlessModal provides modal lifecycle management without any styling.
 *
 * It handles:
 * - ESC key to close (unless closeExplicitly is true)
 * - Preventing close during transition
 * - Providing a close function to children
 */
export function HeadlessModal({ modal, onClose, children }: HeadlessModalProps) {
  const isClosingRef = useRef(false);
  const config = mergeModalConfig(modal.config);

  const close = useCallback(() => {
    if (isClosingRef.current) return;
    isClosingRef.current = true;
    onClose();
    // Reset after a tick to handle rapid close attempts
    setTimeout(() => {
      isClosingRef.current = false;
    }, 0);
  }, [onClose]);

  // ESC key handler
  useEffect(() => {
    if (config.closeExplicitly) return;

    function handleEscape(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        e.preventDefault();
        close();
      }
    }

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [config.closeExplicitly, close]);

  return <>{children({ close, config })}</>;
}

export default HeadlessModal;
