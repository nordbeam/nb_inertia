/**
 * Page-scoped props for Vue 3.
 *
 * Bind the generated `Pages` map once in app glue:
 *
 * ```ts
 * import type { Pages } from '@/types/pageSchemas'
 * import { createUsePageProps } from '@nordbeam/nb-inertia/vue/usePageProps'
 *
 * export const usePageProps = createUsePageProps<Pages>()
 * ```
 *
 * The factory reads the official Inertia Vue `usePage` hook and remains
 * independent from the optional schema runtime.
 */

import type { PageProps as InertiaPageProps } from "@inertiajs/core";
import { usePage as inertiaUsePage } from "@inertiajs/vue3";
import {
  createPagePropsHook,
  type PageMap,
  type PagePropsHookOptions,
  type PageSnapshotLike,
  type UsePageProps,
} from "../shared/pageProps";

export type {
  PageMap,
  PagePropsHookOptions,
  PagePropsMismatch,
  PageSnapshotLike,
  UsePageProps,
} from "../shared/pageProps";
export { PagePropsComponentMismatchError } from "../shared/pageProps";

function currentPage(): PageSnapshotLike {
  return inertiaUsePage<InertiaPageProps>() as unknown as PageSnapshotLike;
}

/**
 * Create a page-scoped hook bound to a generated `Pages` map.
 *
 * The returned function has the generated-friendly signature
 * `<K extends keyof Pages>(expected: K) => Pages[K]`.
 */
export function createUsePageProps<Pages extends PageMap>(
  options: PagePropsHookOptions = {},
): UsePageProps<Pages> {
  return createPagePropsHook<Pages>(currentPage, options);
}

const defaultUsePageProps = createUsePageProps<Record<string, unknown>>();

/**
 * Convenience hook for callers that do not need typed page access. Generated
 * apps should export the map-bound `createUsePageProps<Pages>()` result above;
 * a type map cannot be inferred from a runtime component string here.
 */
export function usePageProps<K extends string>(expected: K): Record<string, unknown>;
export function usePageProps(expected: PropertyKey): unknown {
  return defaultUsePageProps(String(expected));
}

export default usePageProps;
