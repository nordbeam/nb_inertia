import type { PageProps, SharedPageProps } from '@inertiajs/core';
import { computed, inject, provide, type ComputedRef, type InjectionKey } from 'vue';

export interface ModalPageObject<TProps = Record<string, unknown>> {
  component: string;
  props: TProps;
  url: string;
  version: string | number | null;
  flash?: Record<string, unknown>;
  scrollRegions?: Array<{ top: number; left: number }>;
  rememberedState?: Record<string, unknown>;
  clearHistory?: boolean;
  encryptHistory?: boolean;
  preserveFragment?: boolean;
}

export type ModalPageRef = ComputedRef<ModalPageObject | null>;

export const MODAL_PAGE_KEY: InjectionKey<ModalPageRef> = Symbol('nbInertiaModalPage');

export function provideModalPageContext(page: ModalPageRef): void {
  provide(MODAL_PAGE_KEY, page);
}

export function useModalPageContext(): ModalPageRef | null {
  return inject(MODAL_PAGE_KEY, null);
}

export function useIsInModal(): ComputedRef<boolean> {
  const modalPage = useModalPageContext();
  return computed(() => modalPage?.value != null);
}

export type ModalPage<TProps extends PageProps = PageProps> = {
  component: string;
  props: TProps & SharedPageProps;
  url: string;
  version: string | number | null;
  flash?: Record<string, unknown>;
  scrollRegions?: Array<{ top: number; left: number }>;
  rememberedState?: Record<string, unknown>;
  clearHistory?: boolean;
  encryptHistory?: boolean;
  preserveFragment?: boolean;
};
