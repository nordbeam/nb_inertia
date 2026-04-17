import { Page as Page_2 } from '@inertiajs/core';
import { PageProps } from '@inertiajs/core';
import { SharedPageProps } from '@inertiajs/core';

/**
 * Page object structure (matches Inertia's Page type)
 */
export declare type Page<TProps extends PageProps = PageProps> = Omit<Page_2<TProps & SharedPageProps>, 'version'> & {
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
declare function usePage<TProps extends PageProps = PageProps>(): Page<TProps>;
export default usePage;
export { usePage }

export { }
