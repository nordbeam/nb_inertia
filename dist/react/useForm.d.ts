import { useForm as useInertiaForm } from '@inertiajs/react';
import { RouteResult } from './router';
/**
 * Submit options when bound to a route
 *
 * When the form is bound to a RouteResult, submit() only needs visit options
 * since the URL and method come from the bound route.
 */
export type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useInertiaForm>['submit']>[2], never>;
/**
 * Submit options when not bound to a route
 *
 * When the form is not bound, submit() requires method and URL like standard Inertia.
 */
export type UnboundSubmitOptions = {
    method: 'get' | 'post' | 'put' | 'patch' | 'delete';
    url: string;
    options?: BoundSubmitOptions;
};
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
     *
     * @example
     * const form = useForm({ title: 'Post' }, update_post_path.patch(1));
     * form.submit({ preserveScroll: true });
     */
    submit(options?: BoundSubmitOptions): void;
    /**
     * Transform form data before submission
     *
     * Callback receives the form data with proper typing and can return transformed data.
     *
     * @param callback - Function that receives form data (typed as TForm) and returns transformed data
     *
     * @example
     * const form = useForm({ name: 'John' }, user_path.post());
     * form.transform((data) => ({ user: data })); // data is automatically typed as TForm
     */
    transform(callback: (data: TForm) => Record<string, any>): void;
};
/**
 * Enhanced form type when not bound to a route
 *
 * The submit method works exactly like standard Inertia useForm.
 * The transform method is properly typed to preserve TForm generic.
 */
export type UnboundFormType<TForm> = Omit<ReturnType<typeof useInertiaForm<TForm>>, 'transform'> & {
    /**
     * Transform form data before submission
     *
     * Callback receives the form data with proper typing and can return transformed data.
     *
     * @param callback - Function that receives form data (typed as TForm) and returns transformed data
     *
     * @example
     * const form = useForm({ name: 'John' });
     * form.transform((data) => ({ user: data })); // data is automatically typed as TForm
     */
    transform(callback: (data: TForm) => Record<string, any>): void;
};
/**
 * Enhanced useForm hook with optional route binding
 *
 * Wraps Inertia.js useForm to provide optional route binding from nb_routes rich mode.
 * When bound to a route, the submit method automatically uses the route's URL and method.
 * When not bound, works exactly like standard Inertia useForm.
 *
 * Features:
 * - Optional route binding via RouteResult parameter
 * - Bound forms: submit(options?) - URL and method from route
 * - Unbound forms: submit(method, url, options?) - standard Inertia behavior
 * - All other useForm features work unchanged (transform, reset, clearErrors, etc.)
 * - Full TypeScript support with proper type inference
 *
 * @param data - Initial form data
 * @param route - Optional RouteResult from nb_routes for route binding
 * @returns Form object with enhanced submit method when bound
 *
 * @example
 * // Bound to a route - submit() is simplified
 * const form = useForm(
 *   { title: 'My Post', content: 'Content here' },
 *   update_post_path.patch(1)
 * );
 *
 * const handleSubmit = (e) => {
 *   e.preventDefault();
 *   form.submit({
 *     preserveScroll: true,
 *     onSuccess: () => console.log('Saved!'),
 *   });
 * };
 *
 * @example
 * // Not bound - works like standard Inertia
 * const form = useForm({ title: 'My Post' });
 *
 * const handleSubmit = (e) => {
 *   e.preventDefault();
 *   form.submit('patch', `/posts/${postId}`, {
 *     preserveScroll: true,
 *     onSuccess: () => console.log('Saved!'),
 *   });
 * };
 *
 * @example
 * // Access all standard useForm features
 * const form = useForm({ name: '' }, user_path.post());
 *
 * // All these work the same as standard useForm
 * form.setData('name', 'John');
 * form.setData({ name: 'Jane', email: 'jane@example.com' });
 * form.transform((data) => ({ ...data, timestamp: Date.now() }));
 * form.reset();
 * form.reset('name');
 * form.clearErrors();
 * form.clearErrors('name');
 *
 * // Check form state
 * console.log(form.data);
 * console.log(form.errors);
 * console.log(form.processing);
 * console.log(form.progress);
 * console.log(form.wasSuccessful);
 * console.log(form.recentlySuccessful);
 * console.log(form.isDirty);
 */
export declare function useForm<TForm extends Record<string, any>>(data: TForm, route?: RouteResult): RouteResult extends typeof route ? BoundFormType<TForm> : UnboundFormType<TForm>;
export default useForm;
//# sourceMappingURL=useForm.d.ts.map