/**
 * Page-scoped props for React.
 *
 * Bind the generated `Pages` map once:
 *
 * ```tsx
 * import type { Pages } from '@/types/pageSchemas'
 * import { createUsePageProps } from '@nordbeam/nb-inertia/react/usePageProps'
 *
 * export const usePageProps = createUsePageProps<Pages>()
 * // usePageProps('Users/Index') -> Pages['Users/Index']
 * ```
 *
 * The accessor calls nb_inertia's enhanced `usePage` hook so typed props work
 * for both official Inertia pages and modal page contexts. It has no schema
 * runtime dependency, so importing it does not add validation code to an app
 * that only wants typed page access.
 */

import type { PageProps as InertiaPageProps } from "@inertiajs/core";
import { usePage as inertiaUsePage } from "./usePage";
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
 * The returned function is the intentionally narrow API consumed by generated
 * app glue: `<K extends keyof Pages>(expected: K) => Pages[K]`.
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
