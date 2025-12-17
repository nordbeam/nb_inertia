import { useForm as useInertiaForm, InertiaPrecognitiveFormProps as InertiaPrecognitiveFormPropsBase } from '@inertiajs/react';
import { RouteResult } from '../shared/types';
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';
/**
 * HTTP methods supported by forms
 */
export type Method = 'get' | 'post' | 'put' | 'patch' | 'delete';
/**
 * Submit options when form is bound to a route
 */
export type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useInertiaForm>['submit']>[2], never>;
/**
 * Arguments for withPrecognition method
 * Supports: (method, url) | (RouteResult) | (() => RouteResult)
 */
export type WithPrecognitionArgs = [Method | (() => Method), string | (() => string)] | [RouteResult | (() => RouteResult)];
/**
 * Form type when NOT bound to a route (standard Inertia form)
 */
export type UnboundFormType<TForm extends object> = ReturnType<typeof useInertiaForm<TForm>>;
/**
 * Form type when bound to a route
 * - submit() takes no method/url arguments
 * - All other methods work the same
 */
export type BoundFormType<TForm extends object> = Omit<UnboundFormType<TForm>, 'submit'> & {
    /**
     * Submit the form using the bound route's URL and method
     * @param options - Optional visit options (preserveState, preserveScroll, etc.)
     */
    submit(options?: BoundSubmitOptions): void;
};
/**
 * Form type with Precognition enabled (has validation methods)
 * This matches the official Inertia Precognitive form type
 */
export type PrecognitiveFormType<TForm extends object> = InertiaPrecognitiveFormPropsBase<TForm>;
/**
 * Form type with both route binding AND Precognition
 * - submit() uses bound route
 * - Has all validation methods (validate, touch, invalid, valid, etc.)
 */
export type BoundPrecognitiveFormType<TForm extends object> = Omit<PrecognitiveFormType<TForm>, 'submit'> & {
    /**
     * Submit the form using the bound route's URL and method
     * @param options - Optional visit options
     */
    submit(options?: BoundSubmitOptions): void;
};
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
export declare function useForm<TForm extends Record<string, any>>(route: RouteResult, data: TForm): BoundPrecognitiveFormType<TForm>;
/**
 * Create form with route binding (no Precognition)
 *
 * @example
 * ```tsx
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * form.submit(); // Uses PATCH /users/1
 * ```
 */
export declare function useForm<TForm extends Record<string, any>>(data: TForm, route: RouteResult): BoundFormType<TForm>;
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
export declare function useForm<TForm extends Record<string, any>>(data: TForm): UnboundFormType<TForm>;
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
export default useForm;
//# sourceMappingURL=useForm.d.ts.map