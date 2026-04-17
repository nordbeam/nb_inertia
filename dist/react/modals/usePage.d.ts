import { Page as InertiaPage, PageProps, SharedPageProps } from '@inertiajs/core';
/**
 * Page object structure (matches Inertia's Page type)
 */
export type Page<TProps extends PageProps = PageProps> = Omit<InertiaPage<TProps & SharedPageProps>, 'version'> & {
    version: string | number | null;
    scrollRegions?: Array<{
        top: number;
        left: number;
    }>;
};
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
export declare function usePage<TProps extends PageProps = PageProps>(): Page<TProps>;
export default usePage;
//# sourceMappingURL=usePage.d.ts.map