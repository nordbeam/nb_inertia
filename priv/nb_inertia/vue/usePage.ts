import type { Page as InertiaPage, PageProps, SharedPageProps } from '@inertiajs/core';
import { computed, reactive } from 'vue';
import { usePage as inertiaUsePage } from '@inertiajs/vue3';
import { useModalPageContext } from './modalPageContext';

export type Page<TProps extends PageProps = PageProps> = Omit<
  InertiaPage<TProps & SharedPageProps>,
  'version'
> & {
  version: string | number | null;
  flash?: Record<string, unknown>;
  scrollRegions?: Array<{ top: number; left: number }>;
};

export function usePage<TProps extends PageProps = PageProps>(): Page<TProps> {
  const modalPage = useModalPageContext();

  if (modalPage) {
    return reactive({
      props: computed(() => (modalPage.value?.props ?? {}) as TProps & SharedPageProps),
      url: computed(() => modalPage.value?.url ?? ''),
      component: computed(() => modalPage.value?.component ?? ''),
      version: computed(() => modalPage.value?.version ?? null),
      clearHistory: computed(() => modalPage.value?.clearHistory),
      preserveFragment: computed(() => modalPage.value?.preserveFragment),
      encryptHistory: computed(() => modalPage.value?.encryptHistory),
      deferredProps: computed(() => modalPage.value?.deferredProps),
      initialDeferredProps: computed(() => modalPage.value?.initialDeferredProps),
      rescuedProps: computed(() => modalPage.value?.rescuedProps ?? []),
      mergeProps: computed(() => modalPage.value?.mergeProps),
      prependProps: computed(() => modalPage.value?.prependProps),
      deepMergeProps: computed(() => modalPage.value?.deepMergeProps),
      matchPropsOn: computed(() => modalPage.value?.matchPropsOn),
      sharedProps: computed(() => modalPage.value?.sharedProps),
      scrollProps: computed(() => modalPage.value?.scrollProps),
      flash: computed(() => modalPage.value?.flash ?? {}),
      onceProps: computed(() => modalPage.value?.onceProps),
      optimisticUpdatedAt: computed(() => modalPage.value?.optimisticUpdatedAt),
      scrollRegions: computed(() => modalPage.value?.scrollRegions ?? []),
      rememberedState: computed(() => modalPage.value?.rememberedState ?? {}),
    }) as Page<TProps>;
  }

  return inertiaUsePage<TProps>() as Page<TProps>;
}

export default usePage;
