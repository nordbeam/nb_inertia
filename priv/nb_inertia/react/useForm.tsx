/**
 * NbInertia Enhanced useForm Hook for React
 *
 * Provides an enhanced Inertia.js useForm hook that optionally accepts a RouteResult
 * from nb_routes rich mode for route binding. When bound to a route, the submit method
 * automatically uses the route's URL and method without needing to pass them explicitly.
 *
 * NOTE: The official Inertia.js useForm already supports UrlMethodPair in submit().
 * This hook adds a "route binding" pattern where you bind the route at creation time.
 *
 * @example
 * import { useForm } from '@nordbeam/nb-inertia/react';
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

import { useForm as useInertiaForm } from '@inertiajs/react';
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult for convenience
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
export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route?: RouteResult
): RouteResult extends typeof route ? BoundFormType<TForm> : UnboundFormType<TForm>;

export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route?: RouteResult
): BoundFormType<TForm> | UnboundFormType<TForm> {
  const inertiaForm = useInertiaForm<TForm>(data);

  // If no route is provided, return the form with properly typed transform
  if (!route || !isRouteResult(route)) {
    const unboundForm: UnboundFormType<TForm> = {
      ...inertiaForm,
      transform(callback: (data: TForm) => Record<string, any>) {
        return inertiaForm.transform(callback);
      },
    };
    return unboundForm as any;
  }

  // Route is provided - return enhanced form with bound submit and typed transform
  const boundForm: BoundFormType<TForm> = {
    ...inertiaForm,
    submit(options?: BoundSubmitOptions) {
      return inertiaForm.submit(route.method, route.url, options);
    },
    transform(callback: (data: TForm) => Record<string, any>) {
      return inertiaForm.transform(callback);
    },
  };

  return boundForm as any;
}

export default useForm;
