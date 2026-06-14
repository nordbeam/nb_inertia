import type { DefineComponent } from 'vue';

export interface CloseButtonProps {
  class?: string;
  position?: 'top-right' | 'top-left' | 'custom';
  size?: 'sm' | 'md' | 'lg';
  colorClasses?: string;
  ariaLabel?: string;
}

export interface CloseButtonEmits {
  close: [];
}

declare const CloseButton: DefineComponent<CloseButtonProps, Record<string, never>, unknown>;
export default CloseButton;
