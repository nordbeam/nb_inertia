/**
 * NbInertia Enhanced useForm Composable for Vue
 *
 * Provides an enhanced Inertia.js useForm composable that supports:
 * 1. Route binding via RouteResult from nb_routes (delegates to v3 native)
 * 2. Precognition for real-time validation (v3 native)
 * 3. Convenience overload: useForm(data, route) swaps args for v3
 *
 * In Inertia v3, useForm natively supports RouteResult (UrlMethodPair) objects
 * as the first argument, returning a form with bound submit(). This wrapper
 * preserves the nb_inertia API while delegating to v3's implementation.
 *
 * @example Basic route binding
 * ```vue
 * <script setup>
 * import { useForm } from '@nordbeam/nb-inertia/vue/useForm';
 * import { update_user_path } from '@/routes';
 *
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * // form.submit() automatically uses PATCH /users/1
 * </script>
 * ```
 *
 * @example Precognition shorthand
 * ```vue
 * <script setup>
 * import { useForm } from '@nordbeam/nb-inertia/vue/useForm';
 * import { store_user_path } from '@/routes';
 *
 * const form = useForm(store_user_path.post(), { name: '', email: '' });
 * // form.validate('email') validates against POST /users
 * // form.submit() submits to POST /users
 * </script>
 * ```
 */

import type { FormDataType, Method, UrlMethodPair } from '@inertiajs/core';
import {
  useForm as useInertiaForm,
  type InertiaForm,
  type InertiaPrecognitiveForm,
} from '@inertiajs/vue3';
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult and type guard for convenience
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';

type FormDataArgument<TForm> = TForm | (() => TForm);
type RouteResolver = () => UrlMethodPair;
type RouteLike = RouteResult | RouteResolver;
type ReservedFormKeys = keyof InertiaForm<any>;
type ValidateFormData<T> = {
  [K in keyof T]: K extends ReservedFormKeys
    ? ['Error: This field name is reserved by useForm:', K]
    : T[K];
};

function isRouteLike(value: unknown): value is RouteLike {
  return typeof value === 'function' || isRouteResult(value);
}

/**
 * Create standard form with no initial data.
 */
export function useForm<TForm extends FormDataType<TForm>>(): InertiaForm<TForm>;

/**
 * Create standard form with inline or lazy initial data.
 */
export function useForm<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  data: FormDataArgument<TForm>
): InertiaForm<TForm>;

/**
 * Create standard form with remember key support.
 */
export function useForm<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  rememberKey: string,
  data: FormDataArgument<TForm>
): InertiaForm<TForm>;

/**
 * Create a precognitive form from explicit method, URL, and data.
 */
export function useForm<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  method: Method | (() => Method),
  url: string | (() => string),
  data: FormDataArgument<TForm>
): InertiaPrecognitiveForm<TForm>;

/**
 * Create a precognitive form from a route result or lazy route resolver.
 */
export function useForm<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  route: UrlMethodPair | RouteResolver,
  data: FormDataArgument<TForm>
): InertiaPrecognitiveForm<TForm>;

/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
export function useForm<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  data: FormDataArgument<TForm>,
  route: RouteLike
): InertiaPrecognitiveForm<TForm>;

/**
 * Implementation — delegates entirely to Inertia v3's native useForm.
 *
 * v3's useForm natively supports UrlMethodPair as first arg.
 * Vue's InertiaForm is reactive — we never spread it.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  ...args:
    | []
    | [FormDataArgument<TForm>]
    | [string, FormDataArgument<TForm>]
    | [Method | (() => Method), string | (() => string), FormDataArgument<TForm>]
    | [UrlMethodPair | RouteResolver, FormDataArgument<TForm>]
    | [FormDataArgument<TForm>, RouteLike]
): InertiaForm<TForm> | InertiaPrecognitiveForm<TForm> {
  if (args.length === 0) {
    return useInertiaForm<TForm>();
  }

  if (args.length === 3) {
    const [method, url, data] = args;
    return useInertiaForm<TForm>(method, url, data);
  }

  if (args.length === 2) {
    const [first, second] = args;

    if (typeof first === 'string' && !isRouteLike(second)) {
      return useInertiaForm<TForm>(first, second);
    }

    if (isRouteLike(first)) {
      return useInertiaForm<TForm>(first, second as FormDataArgument<TForm>);
    }

    if (typeof first !== 'string' && isRouteLike(second)) {
      return useInertiaForm<TForm>(second, first as FormDataArgument<TForm>);
    }
  }

  return useInertiaForm<TForm>(args[0] as FormDataArgument<TForm>);
}

// ============================================================================
// Helper: Separate validation and submission endpoints
// ============================================================================

/**
 * Create a form with Precognition using separate validation and submission routes.
 *
 * @example
 * ```ts
 * const form = useFormWithPrecognition(
 *   { name: '', email: '' },
 *   validate_user_path.post(),   // Validation endpoint
 *   store_user_path.post()       // Submission endpoint
 * );
 * ```
 */
export function useFormWithPrecognition<TForm extends FormDataType<TForm> & ValidateFormData<TForm>>(
  data: FormDataArgument<TForm>,
  validationRoute: RouteResult,
  submitRoute?: RouteResult
): InertiaPrecognitiveForm<TForm> {
  const form = useInertiaForm<TForm>(validationRoute, data);

  if (
    !submitRoute ||
    (submitRoute.url === validationRoute.url && submitRoute.method === validationRoute.method)
  ) {
    return form;
  }

  // Different submit route: wrap submit to use the submission endpoint
  return new Proxy(form, {
    get(target, prop, receiver) {
      if (prop === 'submit') {
        return (options?: any) =>
          target.submit(submitRoute.method, submitRoute.url, options);
      }
      return Reflect.get(target, prop, receiver);
    },
  }) as InertiaPrecognitiveForm<TForm>;
}

export default useForm;
