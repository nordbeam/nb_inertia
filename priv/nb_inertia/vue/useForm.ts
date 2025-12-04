/**
 * NbInertia Enhanced useForm Composable for Vue
 *
 * Provides an enhanced Inertia.js useForm composable that optionally accepts a RouteResult
 * from nb_routes rich mode for route binding. When bound to a route, the submit method
 * automatically uses the route's URL and method without needing to pass them explicitly.
 *
 * NOTE: The official Inertia.js useForm already supports UrlMethodPair in submit().
 * This composable adds a "route binding" pattern where you bind the route at creation time.
 *
 * @example
 * import { useForm } from '@nordbeam/nb-inertia/vue';
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
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult for convenience
export type { RouteResult } from '../shared/types';

/**
 * Submit options when bound to a route
 */
export type BoundSubmitOptions = VisitOptions;

/**
 * Enhanced form type when bound to a route
 */
export interface BoundFormType<TForm> extends Omit<InertiaForm<TForm>, 'submit'> {
  /**
   * Submit the form using the bound route's URL and method
   *
   * @param options - Optional visit options (preserveState, preserveScroll, etc.)
   */
  submit(options?: BoundSubmitOptions): void;
}

/**
 * Enhanced form type when not bound to a route
 */
export type UnboundFormType<TForm> = InertiaForm<TForm>;

/**
 * Enhanced useForm composable with optional route binding
 *
 * @param data - Initial form data
 * @param route - Optional RouteResult from nb_routes for route binding
 * @returns Form object with enhanced submit method when bound
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
      return inertiaForm.submit(route.method as Method, route.url, options);
    },
  };

  return boundForm as any;
}

export default useForm;
