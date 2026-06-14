import type { Component, DefineComponent } from 'vue';
import type { ModalConfig } from './types';

export interface ModalProps {
  component: Component;
  componentProps?: Record<string, unknown>;
  config?: ModalConfig;
  baseUrl: string;
  open?: boolean;
  className?: string;
}

export interface ModalEmits {
  close: [];
}

declare const Modal: DefineComponent<ModalProps, Record<string, never>, unknown>;
export default Modal;
