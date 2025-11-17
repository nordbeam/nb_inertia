import React, { useEffect, useState, useCallback } from 'react';
import { router } from '../router';
import { useModalStack } from './modalStack';
import type { ModalConfig, ModalInstance } from './types';

export { useModalStack, useModal, ModalStackProvider } from './modalStack';
export type { ModalConfig, ModalInstance, ModalEventType, ModalEventHandler } from './modalStack';

/**
 * Props for HeadlessModal component
 */
export interface HeadlessModalProps {
  /**
   * Unique identifier for this modal
   */
  id?: string;

  /**
   * Modal component to render
   */
  component: React.ComponentType<any>;

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
  children?: (modal: ModalInstance, close: () => void) => React.ReactNode;
}

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
export const HeadlessModal: React.FC<HeadlessModalProps> = ({
  id,
  component: Component,
  componentProps = {},
  config = {},
  baseUrl,
  open = true,
  onClose,
  onSuccess,
  children,
}) => {
  const { pushModal, popModal, emitEvent } = useModalStack();
  const [modalId, setModalId] = useState<string | null>(id || null);
  const [isClosing, setIsClosing] = useState(false);

  // Register modal in stack when opened
  useEffect(() => {
    if (open && !modalId) {
      const newId = pushModal({
        component: Component,
        props: componentProps,
        config,
        baseUrl,
      });
      setModalId(newId);
    }
  }, [open, modalId, pushModal, Component, componentProps, config, baseUrl]);

  // Close modal function
  const close = useCallback(async (success = false) => {
    if (!modalId || isClosing) return;

    setIsClosing(true);

    // Emit beforeClose event - can be canceled
    const shouldClose = await emitEvent(modalId, 'beforeClose');
    if (!shouldClose) {
      setIsClosing(false);
      return;
    }

    // Emit close or success event
    await emitEvent(modalId, success ? 'success' : 'close');

    // Remove from stack
    popModal(modalId);

    // Call callbacks
    if (success && onSuccess) {
      onSuccess();
    } else if (!success && onClose) {
      onClose();
    }

    // Navigate to base URL
    if (baseUrl) {
      router.visit(baseUrl);
    }

    setModalId(null);
    setIsClosing(false);
  }, [modalId, isClosing, emitEvent, popModal, onSuccess, onClose, baseUrl]);

  // Handle ESC key
  useEffect(() => {
    if (!open || !modalId || config.closeExplicitly) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        close();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [open, modalId, config.closeExplicitly, close]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (modalId) {
        popModal(modalId);
      }
    };
  }, [modalId, popModal]);

  if (!open || !modalId) {
    return null;
  }

  // If children function is provided, use render prop pattern
  if (children && modalId) {
    const modal = {
      id: modalId,
      component: Component,
      props: componentProps,
      config,
      baseUrl,
      index: 0,
      eventHandlers: new Map(),
    };
    return <>{children(modal, close)}</>;
  }

  // Default: render the component
  return <Component {...componentProps} close={close} />;
};

export default HeadlessModal;
