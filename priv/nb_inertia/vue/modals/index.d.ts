/**
 * Type declarations for @nordbeam/nb-inertia/vue/modals
 *
 * This file provides vue-tsc-compatible type declarations. It avoids importing
 * .vue files directly, which require allowArbitraryExtensions (TypeScript 5.0+)
 * or a Vue language plugin to resolve from within node_modules.
 *
 * The runtime entry (index.ts) imports the actual .vue SFCs; this file covers
 * only the type surface used by consumers via the package "types" field.
 */

import type { Component, DefineComponent, InjectionKey } from 'vue';
import type { RouteResult } from '../../shared/types';
import type { ModalPageObject } from '../modalPageContext';

export type { ModalPageObject } from '../modalPageContext';

// ---------------------------------------------------------------------------
// Modal configuration types
// ---------------------------------------------------------------------------

export type ModalSize =
  | 'sm'
  | 'md'
  | 'lg'
  | 'xl'
  | '2xl'
  | '3xl'
  | '4xl'
  | '5xl'
  | 'full'
  | (string & {});

export type ModalPosition = 'center' | 'top' | 'bottom' | 'left' | 'right' | (string & {});

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

export type ModalEventType = 'close' | 'success' | 'blur' | 'focus' | 'beforeClose';

export type ModalEventHandler = (modal: ModalInstance) => void | boolean | Promise<void | boolean>;

export interface ModalInstance {
  id: string;
  component: Component;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  props: Record<string, any>;
  page?: ModalPageObject;
  config: ModalConfig;
  baseUrl: string;
  index: number;
  eventHandlers: Map<ModalEventType, Set<ModalEventHandler>>;
}

export interface ModalStackState {
  modals: ModalInstance[];
  pushModal(modal: Omit<ModalInstance, 'id' | 'index' | 'eventHandlers'>): string;
  popModal(id: string): void;
  clearModals(): void;
  getModal(id: string): ModalInstance | undefined;
  addEventListener(id: string, event: ModalEventType, handler: ModalEventHandler): void;
  removeEventListener(id: string, event: ModalEventType, handler: ModalEventHandler): void;
  emitEvent(id: string, event: ModalEventType): Promise<boolean>;
}

export declare const DEFAULT_MODAL_CONFIG: Required<ModalConfig>;
export declare function mergeModalConfig(config?: ModalConfig): Required<ModalConfig>;

// ---------------------------------------------------------------------------
// Modal stack composables
// ---------------------------------------------------------------------------

export declare const MODAL_STACK_KEY: InjectionKey<ModalStackState>;

export declare function createModalStack(
  onStackChange?: (modals: ModalInstance[]) => void,
): ModalStackState;

export declare function useModalStack(): ModalStackState;

export declare function useModal(): ModalInstance | null;

// ---------------------------------------------------------------------------
// Vue SFC component declarations
// Declared inline — no .vue imports — so that tsc/vue-tsc can resolve these
// types from node_modules without needing allowArbitraryExtensions.
// ---------------------------------------------------------------------------

export declare const Modal: DefineComponent<
  {
    component: Component;
    componentProps?: Record<string, unknown>;
    config?: ModalConfig;
    baseUrl: string;
    open?: boolean;
    className?: string;
  },
  Record<string, never>,
  unknown
>;

export declare const HeadlessModal: DefineComponent<
  {
    id?: string;
    component: Component;
    componentProps?: Record<string, unknown>;
    config?: ModalConfig;
    baseUrl: string;
    open?: boolean;
    page?: Partial<ModalPageObject>;
  },
  Record<string, never>,
  unknown
>;

type _PrefetchMode = 'hover' | 'mount' | 'click';

export declare const ModalLink: DefineComponent<
  {
    href: string | RouteResult;
    modalConfig?: ModalConfig;
    baseUrl?: string;
    method?: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
    data?: Record<string, unknown>;
    class?: string;
    prefetch?: boolean | _PrefetchMode | _PrefetchMode[];
    cacheFor?: number;
    cacheTags?: string[];
    target?: string;
    rel?: string;
    download?: string | boolean;
  },
  Record<string, never>,
  unknown
>;

export declare const ModalContent: DefineComponent<
  {
    config?: ModalConfig;
    class?: string;
    zIndex?: number;
  },
  Record<string, never>,
  unknown
>;

export declare const SlideoverContent: DefineComponent<
  {
    config?: ModalConfig;
    class?: string;
    zIndex?: number;
  },
  Record<string, never>,
  unknown
>;

export declare const CloseButton: DefineComponent<
  {
    class?: string;
    position?: 'top-right' | 'top-left' | 'custom';
    size?: 'sm' | 'md' | 'lg';
    colorClasses?: string;
    ariaLabel?: string;
  },
  Record<string, never>,
  unknown
>;
