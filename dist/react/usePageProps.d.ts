import { PageMap, PagePropsHookOptions, UsePageProps } from '../shared/pageProps';
export type { PageMap, PagePropsHookOptions, PagePropsMismatch, PageSnapshotLike, UsePageProps, } from '../shared/pageProps';
export { PagePropsComponentMismatchError } from '../shared/pageProps';
/**
 * Create a page-scoped hook bound to a generated `Pages` map.
 *
 * The returned function is the intentionally narrow API consumed by generated
 * app glue: `<K extends keyof Pages>(expected: K) => Pages[K]`.
 */
export declare function createUsePageProps<Pages extends PageMap>(options?: PagePropsHookOptions): UsePageProps<Pages>;
/**
 * Convenience hook for callers that do not need typed page access. Generated
 * apps should export the map-bound `createUsePageProps<Pages>()` result above;
 * a type map cannot be inferred from a runtime component string here.
 */
export declare function usePageProps<K extends string>(expected: K): Record<string, unknown>;
export default usePageProps;
//# sourceMappingURL=usePageProps.d.ts.map