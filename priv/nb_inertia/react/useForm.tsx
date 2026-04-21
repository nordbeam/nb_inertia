/**
 * NbInertia Enhanced useForm Hook for React
 *
 * Provides an enhanced Inertia.js useForm hook that supports:
 * 1. Route binding via RouteResult from nb_routes (delegates to v3 native)
 * 2. Precognition for real-time validation (v3 native)
 * 3. Convenience overload: useForm(data, route) swaps args for v3
 *
 * In Inertia v3, useForm natively supports RouteResult (UrlMethodPair) objects
 * as the first argument, returning a form with bound submit(). This wrapper
 * preserves the nb_inertia API (data-first and route-first overloads) while
 * delegating entirely to the native v3 implementation.
 *
 * @example Basic route binding
 * ```tsx
 * import { useForm } from '@nordbeam/nb-inertia/react/useForm';
 * import { update_user_path } from '@/routes';
 *
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * form.submit(); // Automatically uses PATCH /users/1
 * ```
 *
 * @example Precognition shorthand
 * ```tsx
 * import { useForm } from '@nordbeam/nb-inertia/react/useForm';
 * import { store_user_path } from '@/routes';
 *
 * const form = useForm(store_user_path.post(), { name: '', email: '' });
 * form.validate('name'); // Validates against POST /users
 * form.submit(); // Submits to POST /users
 * ```
 *
 * @example Standard (no binding)
 * ```tsx
 * const form = useForm({ name: '' });
 * form.submit('post', '/users');
 * ```
 */

import type { FormDataType, Method, UrlMethodPair } from '@inertiajs/core';
import {
  useForm as useInertiaForm,
  type InertiaFormProps,
  type InertiaPrecognitiveFormProps,
} from '@inertiajs/react';
import { type RouteResult, isRouteResult } from '../shared/types';
import { useModalPageContext } from './modals/modalStack';
import { mergeModalHeaders } from './modals/requestContext';

// Re-export RouteResult and type guard for convenience
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';

type FormDataArgument<TForm> = TForm | (() => TForm);
type RouteResolver = () => UrlMethodPair;
type RouteLike = RouteResult | RouteResolver;

function isRouteLike(value: unknown): value is RouteLike {
  return typeof value === 'function' || isRouteResult(value);
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return Object.prototype.toString.call(value) === '[object Object]';
}

function decorateFormWithModalHeaders<TForm extends FormDataType<TForm>>(
  form: InertiaFormProps<TForm> | InertiaPrecognitiveFormProps<TForm>,
  modalPage:
    | {
        url: string;
        baseUrl?: string;
        returnUrl?: string;
      }
    | null
): InertiaFormProps<TForm> | InertiaPrecognitiveFormProps<TForm> {
  if (!modalPage) {
    return form;
  }

  return new Proxy(form, {
    get(target, prop, receiver) {
      const value = Reflect.get(target, prop, receiver);

      if (
        typeof value !== 'function' ||
        !['submit', 'get', 'post', 'put', 'patch', 'delete'].includes(String(prop))
      ) {
        return value;
      }

      return (...args: unknown[]) => {
        const finalArgs = [...args];
        const lastArg = finalArgs[finalArgs.length - 1];
        const mergedOptions = mergeModalHeaders(
          isPlainObject(lastArg) ? (lastArg as { headers?: Record<string, string> }) : undefined,
          {
            url: modalPage.url,
            baseUrl: modalPage.baseUrl,
            returnUrl: modalPage.returnUrl,
          }
        );

        if (isPlainObject(lastArg)) {
          finalArgs[finalArgs.length - 1] = mergedOptions;
        } else {
          finalArgs.push(mergedOptions);
        }

        return (value as (...innerArgs: unknown[]) => unknown).apply(target, finalArgs);
      };
    },
  }) as InertiaFormProps<TForm> | InertiaPrecognitiveFormProps<TForm>;
}

/**
 * Create standard form with no initial data.
 */
export function useForm<TForm extends FormDataType<TForm>>(): InertiaFormProps<TForm>;

/**
 * Create standard form with inline or lazy initial data.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  data: FormDataArgument<TForm>
): InertiaFormProps<TForm>;

/**
 * Create standard form with remember key support.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  rememberKey: string,
  data: FormDataArgument<TForm>
): InertiaFormProps<TForm>;

/**
 * Create a precognitive form from explicit method, URL, and data.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  method: Method | (() => Method),
  url: string | (() => string),
  data: FormDataArgument<TForm>
): InertiaPrecognitiveFormProps<TForm>;

/**
 * Create a precognitive form from a route result or lazy route resolver.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  route: UrlMethodPair | RouteResolver,
  data: FormDataArgument<TForm>
): InertiaPrecognitiveFormProps<TForm>;

/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  data: FormDataArgument<TForm>,
  route: RouteLike
): InertiaPrecognitiveFormProps<TForm>;

/**
 * Implementation — delegates entirely to Inertia v3's native useForm.
 *
 * v3's useForm(urlMethodPair, data) natively returns a form with bound
 * submit(), so no manual binding or spread is needed.
 *
 * Note: v3 features like optimistic() are automatically available since
 * the return type is inferred from the native useForm hook.
 */
export function useForm<TForm extends FormDataType<TForm>>(
  ...args:
    | []
    | [FormDataArgument<TForm>]
    | [string, FormDataArgument<TForm>]
    | [Method | (() => Method), string | (() => string), FormDataArgument<TForm>]
    | [UrlMethodPair | RouteResolver, FormDataArgument<TForm>]
    | [FormDataArgument<TForm>, RouteLike]
): InertiaFormProps<TForm> | InertiaPrecognitiveFormProps<TForm> {
  const modalPage = useModalPageContext();

  if (args.length === 0) {
    return decorateFormWithModalHeaders(useInertiaForm<TForm>(), modalPage);
  }

  if (args.length === 3) {
    const [method, url, data] = args;
    return decorateFormWithModalHeaders(useInertiaForm<TForm>(method, url, data), modalPage);
  }

  if (args.length === 2) {
    const [first, second] = args;

    if (typeof first === 'string' && !isRouteLike(second)) {
      return decorateFormWithModalHeaders(useInertiaForm<TForm>(first, second), modalPage);
    }

    if (isRouteLike(first)) {
      return decorateFormWithModalHeaders(
        useInertiaForm<TForm>(first, second as FormDataArgument<TForm>),
        modalPage
      );
    }

    if (typeof first !== 'string' && isRouteLike(second)) {
      return decorateFormWithModalHeaders(
        useInertiaForm<TForm>(second, first as FormDataArgument<TForm>),
        modalPage
      );
    }
  }

  return decorateFormWithModalHeaders(
    useInertiaForm<TForm>(args[0] as FormDataArgument<TForm>),
    modalPage
  );
}

// ============================================================================
// Helper: Separate validation and submission endpoints
// ============================================================================

/**
 * Create a form with Precognition using separate validation and submission routes.
 *
 * This is useful when your validation endpoint differs from the submission endpoint.
 *
 * @example
 * ```tsx
 * import { useFormWithPrecognition } from '@nordbeam/nb-inertia/react/useForm';
 * import { validate_user_path, store_user_path } from '@/routes';
 *
 * const form = useFormWithPrecognition(
 *   { name: '', email: '' },
 *   validate_user_path.post(),   // Validation endpoint
 *   store_user_path.post()       // Submission endpoint
 * );
 * ```
 */
export function useFormWithPrecognition<TForm extends FormDataType<TForm>>(
  data: FormDataArgument<TForm>,
  validationRoute: RouteResult,
  submitRoute?: RouteResult
): InertiaPrecognitiveFormProps<TForm> {
  const modalPage = useModalPageContext();
  // v3's useForm natively supports precognition when route is provided
  const form = useInertiaForm<TForm>(validationRoute, data);

  // If same route or no separate submit route, return as-is
  if (
    !submitRoute ||
    (submitRoute.url === validationRoute.url && submitRoute.method === validationRoute.method)
  ) {
    return decorateFormWithModalHeaders(form, modalPage) as InertiaPrecognitiveFormProps<TForm>;
  }

  // Different submit route: wrap submit to use the submission endpoint
  // Use Proxy to avoid breaking v3's form internals (may be class/proxy)
  const submitDecoratedForm = new Proxy(form, {
    get(target, prop, receiver) {
      if (prop === 'submit') {
        return (options?: any) =>
          target.submit(submitRoute.method, submitRoute.url, options);
      }
      return Reflect.get(target, prop, receiver);
    },
  }) as InertiaPrecognitiveFormProps<TForm>;

  return decorateFormWithModalHeaders(
    submitDecoratedForm,
    modalPage
  ) as InertiaPrecognitiveFormProps<TForm>;
}

export default useForm;
