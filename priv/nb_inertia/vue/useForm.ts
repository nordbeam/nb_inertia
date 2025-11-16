/**
 * NbInertia Enhanced useForm Composable for Vue
 *
 * Provides an enhanced Inertia.js useForm composable that optionally accepts a RouteResult
 * from nb_routes rich mode for route binding. When bound to a route, the submit method
 * automatically uses the route's URL and method without needing to pass them explicitly.
 *
 * @example
 * import { useForm } from '@/nb_inertia/useForm';
 * import { update_post_path } from '@/routes';
 *
 * // Bound to a route - submit() uses route's URL and method
 * const form = useForm({ title: 'Post Title' }, update_post_path.patch(1));
 * form.submit(); // Automatically uses PATCH /posts/1
 *
 * // Unbound - works like standard Inertia useForm
 * const form = useForm({ title: 'Post Title' });
 * form.submit('patch', '/posts/1'); // Must specify method and URL
 */

import { useForm as useInertiaForm } from '@inertiajs/vue3';
import type { InertiaForm, Method, VisitOptions } from '@inertiajs/vue3';
import type { RouteResult } from './router';

/**
 * Submit options when bound to a route
 *
 * When the form is bound to a RouteResult, submit() only needs visit options
 * since the URL and method come from the bound route.
 */
export type BoundSubmitOptions = VisitOptions;

/**
 * Enhanced form type when bound to a route
 *
 * The submit method only needs options since URL and method come from the bound route.
 */
export interface BoundFormType<TForm> extends Omit<InertiaForm<TForm>, 'submit'> {
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
}

/**
 * Enhanced form type when not bound to a route
 *
 * The submit method works exactly like standard Inertia useForm.
 */
export type UnboundFormType<TForm> = InertiaForm<TForm>;

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
function isRouteResult(value: unknown): value is RouteResult {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const obj = value as Record<string, unknown>;

  return (
    typeof obj.url === 'string' &&
    typeof obj.method === 'string' &&
    ['get', 'post', 'put', 'patch', 'delete', 'head'].includes(obj.method)
  );
}

/**
 * Enhanced useForm composable with optional route binding
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
 * const handleSubmit = () => {
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
 * const handleSubmit = () => {
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
 * form.name = 'John';
 * form.setData('name', 'Jane');
 * form.setData({ name: 'Jane', email: 'jane@example.com' });
 * form.transform((data) => ({ ...data, timestamp: Date.now() }));
 * form.reset();
 * form.reset('name');
 * form.clearErrors();
 * form.clearErrors('name');
 *
 * // Check form state
 * console.log(form.data());
 * console.log(form.errors);
 * console.log(form.processing);
 * console.log(form.progress);
 * console.log(form.wasSuccessful);
 * console.log(form.recentlySuccessful);
 * console.log(form.isDirty);
 */
export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route?: RouteResult
): BoundFormType<TForm> | UnboundFormType<TForm> {
  const inertiaForm = useInertiaForm<TForm>(data);

  // If no route is provided, return the standard Inertia form
  if (!route || !isRouteResult(route)) {
    return inertiaForm;
  }

  // Route is provided - return enhanced form with bound submit
  const boundForm: BoundFormType<TForm> = {
    ...inertiaForm,
    submit(options?: BoundSubmitOptions) {
      // Call Inertia's submit with the bound route's method, URL, and options
      return inertiaForm.submit(route.method as Method, route.url, options);
    },
  };

  return boundForm as any;
}

export default useForm;
