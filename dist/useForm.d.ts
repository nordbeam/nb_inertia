import { useForm as useForm_2 } from '@inertiajs/react';

/**
 * Enhanced form type when bound to a route
 *
 * The submit method only needs options since URL and method come from the bound route.
 * The transform method is properly typed to preserve TForm generic.
 */
export declare type BoundFormType<TForm> = Omit<ReturnType<typeof useForm_2<TForm>>, 'submit' | 'transform'> & {
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
 * Submit options when bound to a route
 *
 * When the form is bound to a RouteResult, submit() only needs visit options
 * since the URL and method come from the bound route.
 */
export declare type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useForm_2>['submit']>[2], never>;

/**
 * Shared types and utilities for nb_inertia
 *
 * This module provides common types and utilities used across React and Vue components.
 */
/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing components to automatically use the correct HTTP method.
 *
 * NOTE: This type matches @inertiajs/core's UrlMethodPair type exactly.
 * The official Inertia.js router and Link components already support this pattern.
 */
export declare type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete';
};

/**
 * Enhanced form type when not bound to a route
 *
 * The submit method works exactly like standard Inertia useForm.
 */
export declare type UnboundFormType<TForm> = Omit<ReturnType<typeof useForm_2<TForm>>, 'transform'> & {
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
declare function useForm<TForm extends Record<string, any>>(data: TForm, route?: RouteResult): RouteResult extends typeof route ? BoundFormType<TForm> : UnboundFormType<TForm>;
export default useForm;
export { useForm }

export { }
