import { useForm as useInertiaForm } from '@inertiajs/react';
import { RouteResult } from '../shared/types';
export type { RouteResult } from '../shared/types';
/**
 * Submit options when bound to a route
 *
 * When the form is bound to a RouteResult, submit() only needs visit options
 * since the URL and method come from the bound route.
 */
export type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useInertiaForm>['submit']>[2], never>;
/**
 * Enhanced form type when bound to a route
 *
 * The submit method only needs options since URL and method come from the bound route.
 * The transform method is properly typed to preserve TForm generic.
 */
export type BoundFormType<TForm> = Omit<ReturnType<typeof useInertiaForm<TForm>>, 'submit' | 'transform'> & {
    /**
     * Submit the form using the bound route's URL and method
     *
     * @param options - Optional visit options (preserveState, preserveScroll, etc.)
     */
    submit(options?: BoundSubmitOptions): void;
    /**
     * Transform form data before submission
     *
     * @param callback - Function that receives form data (typed as TForm) and returns transformed data
     */
    transform(callback: (data: TForm) => Record<string, any>): void;
};
/**
 * Enhanced form type when not bound to a route
 *
 * The submit method works exactly like standard Inertia useForm.
 */
export type UnboundFormType<TForm> = Omit<ReturnType<typeof useInertiaForm<TForm>>, 'transform'> & {
    /**
     * Transform form data before submission
     *
     * @param callback - Function that receives form data (typed as TForm) and returns transformed data
     */
    transform(callback: (data: TForm) => Record<string, any>): void;
};
/**
 * Enhanced useForm hook with optional route binding
 *
 * When bound to a route, the submit method automatically uses the route's URL and method.
 * When not bound, works exactly like standard Inertia useForm.
 *
 * @param data - Initial form data
 * @param route - Optional RouteResult from nb_routes for route binding
 * @returns Form object with enhanced submit method when bound
 */
export declare function useForm<TForm extends Record<string, any>>(data: TForm, route?: RouteResult): RouteResult extends typeof route ? BoundFormType<TForm> : UnboundFormType<TForm>;
export default useForm;
//# sourceMappingURL=useForm.d.ts.map