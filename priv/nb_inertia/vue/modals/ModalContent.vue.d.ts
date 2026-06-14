import type { DefineComponent } from 'vue';
import type { ModalConfig } from './types';

export interface ModalContentProps {
  config?: ModalConfig;
  class?: string;
  zIndex?: number;
}

declare const ModalContent: DefineComponent<ModalContentProps, Record<string, never>, unknown>;
export default ModalContent;
