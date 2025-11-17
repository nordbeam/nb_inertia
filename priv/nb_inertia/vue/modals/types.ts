/**
 * Modal Configuration and Type Definitions (Vue)
 *
 * Shared type definitions for the Vue modal system.
 * These types are compatible with the React modal system.
 */

import type { Component } from 'vue';

/**
 * Modal size presets and custom sizes
 */
export type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | 'full' | string;

/**
 * Modal position presets and custom positions
 */
export type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | string;

/**
 * Configuration for a modal instance
 */
export interface ModalConfig {
  size?: ModalSize;
  position?: ModalPosition;
  slideover?: boolean;
  closeButton?: boolean;
  closeExplicitly?: boolean;
  maxWidth?: string;
  paddingClasses?: string;
  panelClasses?: string;
  backdropClasses?: string;
}

/**
 * Modal event types
 */
export type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';

/**
 * Modal event handler function
 */
export type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;

/**
 * Represents a modal instance in the stack
 */
export interface ModalInstance {
  id: string;
  component: Component;
  props: Record<string, any>;
  config: ModalConfig;
  baseUrl: string;
  index: number;
  eventHandlers: Map<ModalEventType, Set<ModalEventHandler>>;
}

/**
 * Modal stack manager state
 */
export interface ModalStackState {
  modals: ModalInstance[];
  pushModal: (modal: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>) => string;
  popModal: (id: string) => void;
  clearModals: () => void;
  getModal: (id: string) => ModalInstance | undefined;
  addEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
  removeEventListener: (id: string, event: ModalEventType, handler: ModalEventHandler) => void;
  emitEvent: (id: string, event: ModalEventType) => Promise<boolean>;
}

/**
 * Default modal configuration
 */
export const DEFAULT_MODAL_CONFIG: Required<ModalConfig> = {
  size: 'md',
  position: 'center',
  slideover: false,
  closeButton: true,
  closeExplicitly: false,
  maxWidth: '',
  paddingClasses: 'p-6',
  panelClasses: 'bg-white rounded-lg shadow-xl',
  backdropClasses: 'bg-black/50',
};

/**
 * Merge user config with defaults
 */
export function mergeModalConfig(config?: ModalConfig): Required<ModalConfig> {
  return {
    ...DEFAULT_MODAL_CONFIG,
    ...config,
  };
}
