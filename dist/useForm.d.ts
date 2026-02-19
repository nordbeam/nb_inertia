import { InertiaPrecognitiveFormProps } from '@inertiajs/react';
import { useForm as useForm_2 } from '@inertiajs/react';

/**
 * Form type when bound to a route
 * - submit() takes no method/url arguments
 * - All other methods work the same
 */
export declare type BoundFormType<TForm extends object> = Omit<UnboundFormType<TForm>, 'submit'> & {
    /**
     * Submit the form using the bound route's URL and method
     * @param options - Optional visit options (preserveState, preserveScroll, etc.)
     */
    submit(options?: BoundSubmitOptions): void;
};

/**
 * Form type with both route binding AND Precognition
 * - submit() uses bound route
 * - Has all validation methods (validate, touch, invalid, valid, etc.)
 */
export declare type BoundPrecognitiveFormType<TForm extends object> = Omit<PrecognitiveFormType<TForm>, 'submit'> & {
    /**
     * Submit the form using the bound route's URL and method
     * @param options - Optional visit options
     */
    submit(options?: BoundSubmitOptions): void;
};

/**
 * Submit options when form is bound to a route
 */
export declare type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useForm_2>['submit']>[2], never>;

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
export declare function isRouteResult(value: unknown): value is RouteResult;

/**
 * HTTP methods supported by forms
 */
export declare type Method = 'get' | 'post' | 'put' | 'patch' | 'delete';

/**
 * Form type with Precognition enabled (has validation methods)
 * This matches the official Inertia Precognitive form type
 */
export declare type PrecognitiveFormType<TForm extends object> = InertiaPrecognitiveFormProps<TForm>;

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
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};

/**
 * Form type when NOT bound to a route (standard Inertia form)
 */
export declare type UnboundFormType<TForm extends object> = ReturnType<typeof useForm_2<TForm>>;

/**
 * Create form with Precognition enabled at creation time using RouteResult
 *
 * @example
 * ```tsx
 * const form = useForm(store_user_path.post(), { name: '', email: '' });
 * form.validate('email');
 * form.submit(); // Uses POST /users
 * ```
 */
declare function useForm<TForm extends Record<string, any>>(route: RouteResult, data: TForm): BoundPrecognitiveFormType<TForm>;

/**
 * Create form with route binding (no Precognition)
 *
 * @example
 * ```tsx
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * form.submit(); // Uses PATCH /users/1
 * ```
 */
declare function useForm<TForm extends Record<string, any>>(data: TForm, route: RouteResult): BoundFormType<TForm>;

/**
 * Create standard form (no binding, no Precognition)
 *
 * @example
 * ```tsx
 * const form = useForm({ name: '' });
 * form.submit('post', '/users');
 *
 * // Or enable Precognition later:
 * const precogForm = form.withPrecognition('post', '/validate');
 * ```
 */
declare function useForm<TForm extends Record<string, any>>(data: TForm): UnboundFormType<TForm>;
export default useForm;
export { useForm }

/**
 * Create an enhanced form with Precognition that accepts RouteResult
 *
 * This is useful when you want to add Precognition to an existing form
 * or when you want different validation and submission endpoints.
 *
 * @example
 * ```tsx
 * import { useFormWithPrecognition } from '@nordbeam/nb-inertia/react/useForm';
 * import { validate_user_path, store_user_path } from '@/routes';
 *
 * // Different validation and submission endpoints
 * const form = useFormWithPrecognition(
 *   { name: '', email: '' },
 *   validate_user_path.post(),   // Validation endpoint
 *   store_user_path.post()       // Submission endpoint
 * );
 * ```
 */
export declare function useFormWithPrecognition<TForm extends Record<string, any>>(data: TForm, validationRoute: RouteResult, submitRoute?: RouteResult): BoundPrecognitiveFormType<TForm> | PrecognitiveFormType<TForm>;

/**
 * Arguments for withPrecognition method
 * Supports: (method, url) | (RouteResult) | (() => RouteResult)
 */
export declare type WithPrecognitionArgs = [Method | (() => Method), string | (() => string)] | [RouteResult | (() => RouteResult)];

export { }
