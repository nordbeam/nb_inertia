/**
 * Enhanced usePage hook for nb_inertia
 *
 * This hook extends Inertia's usePage to work correctly inside modals.
 * When called inside a modal context, it returns the modal's page object
 * instead of throwing an error.
 *
 * @example
 * ```tsx
 * // Import from @/lib/inertia (which re-exports from nb_inertia)
 * import { usePage } from '@/lib/inertia';
 *
 * function MyComponent() {
 *   // Works in both normal pages AND inside modals
 *   const { props } = usePage<MyPageProps>();
 *   return <div>{props.user.name}</div>;
 * }
 * ```
 */
/**
 * Page object structure (matches Inertia's Page type)
 */
export interface Page<TProps = Record<string, any>> {
    component: string;
    props: TProps;
    url: string;
    version: string | null;
    scrollRegions: Array<{
        top: number;
        left: number;
    }>;
    rememberedState: Record<string, unknown>;
    clearHistory: boolean;
    encryptHistory: boolean;
}
/**
 * Enhanced usePage hook
 *
 * Checks if we're inside a modal context first. If so, returns the modal's
 * page object. Otherwise, delegates to Inertia's usePage.
 *
 * This allows components to use usePage() seamlessly whether they're rendered
 * as a full page or inside a modal.
 *
 * @returns The current page object with props
 */
export declare function usePage<TProps = Record<string, any>>(): Page<TProps>;
export default usePage;
//# sourceMappingURL=usePage.d.ts.map