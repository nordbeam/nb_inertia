import type { Component, DefineComponent } from 'vue';
import type { ModalConfig } from './types';
import type { ModalPageObject } from '../modalPageContext';

export interface HeadlessModalProps {
  id?: string;
  component: Component;
  componentProps?: Record<string, unknown>;
  config?: ModalConfig;
  baseUrl: string;
  open?: boolean;
  page?: Partial<ModalPageObject>;
}

export interface HeadlessModalEmits {
  close: [];
  success: [];
}

declare const HeadlessModal: DefineComponent<HeadlessModalProps, Record<string, never>, unknown>;
export default HeadlessModal;
