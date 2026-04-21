/**
 * HeadlessModal - Core modal state management for React
 *
 * Provides foundational modal logic without any UI:
 * - Modal stack integration
 * - Keyboard handling (ESC to close unless closeExplicitly)
 * - Lifecycle management (open/close callbacks)
 * - Modal content context with close/reload/stack metadata
 *
 * Use this as a base for building your own styled modal components.
 */

import React, {
  createContext,
  forwardRef,
  useCallback,
  useContext,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import { router as inertiaRouter } from '@inertiajs/react';
import type { ModalConfig, ModalInstance } from './types';
import { mergeModalConfig } from './types';
import { mergeModalHeaders } from './requestContext';
import { useModalStack } from './modalStack';

type VisitOptions = NonNullable<Parameters<typeof inertiaRouter.visit>[1]>;
type ModalReloadOptions = Omit<VisitOptions, 'method' | 'data' | 'async'>;

export interface ModalHandle {
  modal: ModalInstance;
  id: string;
  index: number;
  onTopOfStack: boolean;
  isOpen: boolean;
  config: ModalConfig;
  close: () => void;
  setOpen: (open: boolean) => void;
  reload: (options?: ModalReloadOptions) => void;
  getParentModal: () => ModalHandle | null;
  getChildModal: () => ModalHandle | null;
}

const CurrentModalContext = createContext<ModalHandle | null>(null);
CurrentModalContext.displayName = 'NbInertiaCurrentModalContext';

export function useCurrentModal(): ModalHandle {
  const context = useContext(CurrentModalContext);

  if (!context) {
    throw new Error('useCurrentModal must be used within a HeadlessModal');
  }

  return context;
}

export interface ModalProps {
  children?: React.ReactNode | ((context: ModalHandle) => React.ReactNode);
}

export const Modal = forwardRef<ModalHandle, ModalProps>(function Modal({ children }, ref) {
  const modal = useCurrentModal();

  useImperativeHandle(ref, () => modal, [modal]);

  if (typeof children === 'function') {
    return <>{children(modal)}</>;
  }

  return <>{children}</>;
});

export interface HeadlessModalProps {
  /** The modal instance from the stack */
  modal: ModalInstance;

  /** Called when the modal should close */
  onClose: () => void;

  /**
   * Whether the modal is currently open.
   * Custom renderers with animations can pass this through for richer context.
   * @default true
   */
  isOpen?: boolean;

  /**
   * Render function receiving modal controls and metadata.
   */
  children: (context: ModalHandle) => React.ReactNode;
}

/**
 * HeadlessModal provides modal lifecycle management without any styling.
 */
export const HeadlessModal = forwardRef<ModalHandle, HeadlessModalProps>(function HeadlessModal(
  { modal, onClose, isOpen = true, children },
  ref
) {
  const isClosingRef = useRef(false);
  const config = mergeModalConfig(modal.config);
  const { modals, popModal } = useModalStack();

  const close = useCallback(() => {
    if (isClosingRef.current) return;
    isClosingRef.current = true;
    onClose();

    setTimeout(() => {
      isClosingRef.current = false;
    }, 0);
  }, [onClose]);

  const setOpen = useCallback(
    (open: boolean) => {
      if (!open) {
        close();
      }
    },
    [close]
  );

  const reloadModal = useCallback((target: ModalInstance, options?: ModalReloadOptions) => {
    inertiaRouter.visit(
      target.url,
      mergeModalHeaders(
        {
          ...(options ?? {}),
          preserveState: options?.preserveState ?? true,
          preserveScroll: options?.preserveScroll ?? true,
        },
        {
          url: target.url,
          baseUrl: target.returnUrl || target.baseUrl,
          returnUrl: target.returnUrl,
        }
      )
    );
  }, []);

  const buildHandle = useCallback(
    (target: ModalInstance): ModalHandle | null => {
      const index = modals.findIndex((item) => item.id === target.id);

      if (index === -1) {
        return null;
      }

      return {
        modal: target,
        id: target.id,
        index,
        onTopOfStack: index === modals.length - 1,
        isOpen: target.id === modal.id ? isOpen : true,
        config: mergeModalConfig(target.config),
        close: () => popModal(target.id),
        setOpen: (open: boolean) => {
          if (!open) {
            popModal(target.id);
          }
        },
        reload: (options?: ModalReloadOptions) => reloadModal(target, options),
        getParentModal: () => {
          const parent = modals[index - 1];
          return parent ? buildHandle(parent) : null;
        },
        getChildModal: () => {
          const child = modals[index + 1];
          return child ? buildHandle(child) : null;
        },
      };
    },
    [isOpen, modal.id, modals, popModal, reloadModal]
  );

  const contextValue = useMemo(() => buildHandle(modal), [buildHandle, modal]);

  useImperativeHandle(ref, () => {
    if (!contextValue) {
      throw new Error('Cannot create modal ref for a modal that is not in the stack');
    }

    return contextValue;
  }, [contextValue]);

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

  if (!contextValue) {
    return null;
  }

  return (
    <CurrentModalContext.Provider value={contextValue}>
      {children(contextValue)}
    </CurrentModalContext.Provider>
  );
});

export default HeadlessModal;
