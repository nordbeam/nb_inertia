import type { DefineComponent } from 'vue';
import type { ModalConfig } from './types';

export interface SlideoverContentProps {
  config?: ModalConfig;
  class?: string;
  zIndex?: number;
}

declare const SlideoverContent: DefineComponent<SlideoverContentProps, Record<string, never>, unknown>;
export default SlideoverContent;
