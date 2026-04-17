/**
 * NbInertia Enhanced useHttp Hook for React
 *
 * Provides an enhanced Inertia.js useHttp hook that supports:
 * 1. Route binding via RouteResult from nb_routes (delegates to v3 native)
 * 2. Precognition for real-time validation (v3 native)
 * 3. Convenience overload: useHttp(data, route) swaps args for v3
 *
 * In Inertia v3, useHttp provides a way to make HTTP requests outside of
 * page navigation (e.g., API calls). It shares the same DX as useForm
 * (isDirty, processing, errors, progress) but returns response data instead
 * of triggering a page visit.
 *
 * Like useForm, useHttp natively supports RouteResult (UrlMethodPair) objects
 * as the first argument. This wrapper preserves the nb_inertia API (data-first
 * and route-first overloads) while delegating entirely to the native v3
 * implementation.
 *
 * @example Basic route binding
 * ```tsx
 * import { useHttp } from '@nordbeam/nb-inertia/react/useHttp';
 * import { api_users_path } from '@/routes';
 *
 * const http = useHttp({ name: '' }, api_users_path.post());
 * http.submit(); // Automatically uses POST /api/users
 * ```
 *
 * @example Precognition shorthand
 * ```tsx
 * import { useHttp } from '@nordbeam/nb-inertia/react/useHttp';
 * import { api_users_path } from '@/routes';
 *
 * const http = useHttp(api_users_path.post(), { name: '', email: '' });
 * http.validate('name'); // Validates against POST /api/users
 * http.submit(); // Submits to POST /api/users
 * ```
 *
 * @example Standard (no binding)
 * ```tsx
 * const http = useHttp({ name: '' });
 * http.submit('post', '/api/users');
 * ```
 */

import type {
  ErrorValue,
  FormDataErrors,
  FormDataKeys,
  FormDataType,
  FormDataValues,
  Method,
  Progress,
  UrlMethodPair,
  UseFormTransformCallback,
  UseFormWithPrecognitionArguments,
  UseHttpSubmitArguments,
  UseHttpSubmitOptions,
} from '@inertiajs/core';
import { useHttp as useInertiaHttp } from '@inertiajs/react';
import type { NamedInputEvent, ValidationConfig, Validator } from 'laravel-precognition';
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult and type guard for convenience
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';

type FormDataArgument<TForm> = TForm | (() => TForm);
type RouteResolver = () => UrlMethodPair;
type RouteLike = RouteResult | RouteResolver;

type SetDataByObject<TForm> = (data: TForm) => void;
type SetDataByMethod<TForm> = (data: (previousData: TForm) => TForm) => void;
type SetDataByKeyValuePair<TForm> = <K extends FormDataKeys<TForm>>(
  key: K,
  value: FormDataValues<TForm, K>
) => void;
type SetDataAction<TForm> =
  & SetDataByObject<TForm>
  & SetDataByMethod<TForm>
  & SetDataByKeyValuePair<TForm>;

type PrecognitionValidationConfig<TKeys> = ValidationConfig & {
  only?: TKeys[] | Iterable<TKeys> | ArrayLike<TKeys>;
};

export interface UseHttpProps<TForm extends object, TResponse = unknown> {
  data: TForm;
  isDirty: boolean;
  errors: FormDataErrors<TForm>;
  hasErrors: boolean;
  processing: boolean;
  progress: Progress | null;
  wasSuccessful: boolean;
  recentlySuccessful: boolean;
  response: TResponse | null;
  setData: SetDataAction<TForm>;
  transform: (callback: UseFormTransformCallback<TForm>) => void;
  setDefaults: {
    (): void;
    <T extends FormDataKeys<TForm>>(field: T, value: FormDataValues<TForm, T>): void;
    (fields: Partial<TForm>): void;
  };
  reset: <K extends FormDataKeys<TForm>>(...fields: K[]) => void;
  clearErrors: <K extends FormDataKeys<TForm>>(...fields: K[]) => void;
  resetAndClearErrors: <K extends FormDataKeys<TForm>>(...fields: K[]) => void;
  setError: {
    <K extends FormDataKeys<TForm>>(field: K, value: ErrorValue): void;
    (errors: FormDataErrors<TForm>): void;
  };
  submit: (...args: UseHttpSubmitArguments<TResponse, TForm>) => Promise<TResponse>;
  get: (url: string, options?: UseHttpSubmitOptions<TResponse, TForm>) => Promise<TResponse>;
  post: (url: string, options?: UseHttpSubmitOptions<TResponse, TForm>) => Promise<TResponse>;
  put: (url: string, options?: UseHttpSubmitOptions<TResponse, TForm>) => Promise<TResponse>;
  patch: (url: string, options?: UseHttpSubmitOptions<TResponse, TForm>) => Promise<TResponse>;
  delete: (url: string, options?: UseHttpSubmitOptions<TResponse, TForm>) => Promise<TResponse>;
  cancel: () => void;
  dontRemember: <K extends FormDataKeys<TForm>>(...fields: K[]) => UseHttpProps<TForm, TResponse>;
  optimistic: (callback: (currentData: TForm) => Partial<TForm>) => UseHttpProps<TForm, TResponse>;
  withAllErrors: () => UseHttpProps<TForm, TResponse>;
  withPrecognition: (...args: UseFormWithPrecognitionArguments) => UseHttpPrecognitiveProps<TForm, TResponse>;
}

export interface UseHttpValidationProps<TForm extends object, TResponse = unknown> {
  invalid: <K extends FormDataKeys<TForm>>(field: K) => boolean;
  setValidationTimeout: (duration: number) => UseHttpPrecognitiveProps<TForm, TResponse>;
  touch: <K extends FormDataKeys<TForm>>(
    field: K | NamedInputEvent | Array<K>,
    ...fields: K[]
  ) => UseHttpPrecognitiveProps<TForm, TResponse>;
  touched: <K extends FormDataKeys<TForm>>(field?: K) => boolean;
  valid: <K extends FormDataKeys<TForm>>(field: K) => boolean;
  validate: <K extends FormDataKeys<TForm>>(
    field?: K | NamedInputEvent | PrecognitionValidationConfig<K>,
    config?: PrecognitionValidationConfig<K>
  ) => UseHttpPrecognitiveProps<TForm, TResponse>;
  validateFiles: () => UseHttpPrecognitiveProps<TForm, TResponse>;
  validating: boolean;
  validator: () => Validator;
  withAllErrors: () => UseHttpPrecognitiveProps<TForm, TResponse>;
  withoutFileValidation: () => UseHttpPrecognitiveProps<TForm, TResponse>;
  setErrors: (errors: FormDataErrors<TForm>) => UseHttpPrecognitiveProps<TForm, TResponse>;
  forgetError: <K extends FormDataKeys<TForm> | NamedInputEvent>(
    field: K
  ) => UseHttpPrecognitiveProps<TForm, TResponse>;
}

export type UseHttp<TForm extends object, TResponse = unknown> = UseHttpProps<TForm, TResponse>;
export type UseHttpPrecognitiveProps<TForm extends object, TResponse = unknown> =
  UseHttpProps<TForm, TResponse> & UseHttpValidationProps<TForm, TResponse>;

function isRouteLike(value: unknown): value is RouteLike {
  return typeof value === 'function' || isRouteResult(value);
}

/**
 * Create standard request with no initial data.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(): UseHttp<TForm, TResponse>;

/**
 * Create standard request with inline or lazy initial data.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  data: FormDataArgument<TForm>
): UseHttp<TForm, TResponse>;

/**
 * Create standard request with remember key support.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  rememberKey: string,
  data: FormDataArgument<TForm>
): UseHttp<TForm, TResponse>;

/**
 * Create a precognitive request from explicit method, URL, and data.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  method: Method | (() => Method),
  url: string | (() => string),
  data: FormDataArgument<TForm>
): UseHttpPrecognitiveProps<TForm, TResponse>;

/**
 * Create a precognitive request from a route result or lazy route resolver.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  route: UrlMethodPair | RouteResolver,
  data: FormDataArgument<TForm>
): UseHttpPrecognitiveProps<TForm, TResponse>;

/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  data: FormDataArgument<TForm>,
  route: RouteLike
): UseHttpPrecognitiveProps<TForm, TResponse>;

/**
 * Implementation — delegates entirely to Inertia v3's native useHttp.
 *
 * v3's useHttp(urlMethodPair, data) natively returns an HTTP request object
 * with bound submit(), so no manual binding or spread is needed.
 *
 * Note: Like useForm, useHttp supports optimistic() and other fluent methods
 * via v3's native implementation. Since the return type is inferred from the
 * native hook, all v3 features are automatically available.
 */
export function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(
  ...args:
    | []
    | [FormDataArgument<TForm>]
    | [string, FormDataArgument<TForm>]
    | [Method | (() => Method), string | (() => string), FormDataArgument<TForm>]
    | [UrlMethodPair | RouteResolver, FormDataArgument<TForm>]
    | [FormDataArgument<TForm>, RouteLike]
): UseHttp<TForm, TResponse> | UseHttpPrecognitiveProps<TForm, TResponse> {
  if (args.length === 0) {
    return useInertiaHttp<TForm, TResponse>();
  }

  if (args.length === 3) {
    const [method, url, data] = args;
    return useInertiaHttp<TForm, TResponse>(method, url, data);
  }

  if (args.length === 2) {
    const [first, second] = args;

    if (typeof first === 'string' && !isRouteLike(second)) {
      return useInertiaHttp<TForm, TResponse>(first, second);
    }

    if (isRouteLike(first)) {
      return useInertiaHttp<TForm, TResponse>(first, second as FormDataArgument<TForm>);
    }

    if (typeof first !== 'string' && isRouteLike(second)) {
      return useInertiaHttp<TForm, TResponse>(second, first as FormDataArgument<TForm>);
    }
  }

  return useInertiaHttp<TForm, TResponse>(args[0] as FormDataArgument<TForm>);
}

// ============================================================================
// Helper: Separate validation and submission endpoints
// ============================================================================

/**
 * Create an HTTP request with Precognition using separate validation and submission routes.
 *
 * This is useful when your validation endpoint differs from the submission endpoint.
 *
 * @example
 * ```tsx
 * import { useHttpWithPrecognition } from '@nordbeam/nb-inertia/react/useHttp';
 * import { validate_user_path, api_users_path } from '@/routes';
 *
 * const http = useHttpWithPrecognition(
 *   { name: '', email: '' },
 *   validate_user_path.post(),   // Validation endpoint
 *   api_users_path.post()        // Submission endpoint
 * );
 * ```
 */
export function useHttpWithPrecognition<TForm extends FormDataType<TForm>, TResponse = unknown>(
  data: FormDataArgument<TForm>,
  validationRoute: RouteResult,
  submitRoute?: RouteResult
): UseHttpPrecognitiveProps<TForm, TResponse> {
  const http = useInertiaHttp<TForm, TResponse>(validationRoute, data);

  // If same route or no separate submit route, return as-is
  if (
    !submitRoute ||
    (submitRoute.url === validationRoute.url && submitRoute.method === validationRoute.method)
  ) {
    return http;
  }

  // Different submit route: wrap submit to use the submission endpoint
  // Use Proxy to avoid breaking v3's internals (may be class/proxy)
  return new Proxy(http, {
    get(target, prop, receiver) {
      if (prop === 'submit') {
        return (options?: any) =>
          target.submit(submitRoute.method, submitRoute.url, options);
      }
      return Reflect.get(target, prop, receiver);
    },
  }) as UseHttpPrecognitiveProps<TForm, TResponse>;
}

export default useHttp;
