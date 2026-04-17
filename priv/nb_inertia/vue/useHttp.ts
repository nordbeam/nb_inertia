/**
 * NbInertia Enhanced useHttp Composable for Vue
 *
 * Provides an enhanced Inertia.js useHttp composable that supports:
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
 * as the first argument. This wrapper preserves the nb_inertia API while
 * delegating to v3's implementation.
 *
 * @example Basic route binding
 * ```vue
 * <script setup>
 * import { useHttp } from '@nordbeam/nb-inertia/vue/useHttp';
 * import { api_users_path } from '@/routes';
 *
 * const http = useHttp({ name: '' }, api_users_path.post());
 * // http.submit() automatically uses POST /api/users
 * </script>
 * ```
 *
 * @example Precognition shorthand
 * ```vue
 * <script setup>
 * import { useHttp } from '@nordbeam/nb-inertia/vue/useHttp';
 * import { api_users_path } from '@/routes';
 *
 * const http = useHttp(api_users_path.post(), { name: '', email: '' });
 * // http.validate('email') validates against POST /api/users
 * // http.submit() submits to POST /api/users
 * </script>
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
import { useHttp as useInertiaHttp } from '@inertiajs/vue3';
import type { NamedInputEvent, ValidationConfig, Validator } from 'laravel-precognition';
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult and type guard for convenience
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';

type FormDataArgument<TForm> = TForm | (() => TForm);
type RouteResolver = () => UrlMethodPair;
type RouteLike = RouteResult | RouteResolver;

type PrecognitionValidationConfig<TKeys> = ValidationConfig & {
  only?: TKeys[] | Iterable<TKeys> | ArrayLike<TKeys>;
};

export interface UseHttpProps<TForm extends object, TResponse = unknown> {
  isDirty: boolean;
  errors: FormDataErrors<TForm>;
  hasErrors: boolean;
  processing: boolean;
  progress: Progress | null;
  wasSuccessful: boolean;
  recentlySuccessful: boolean;
  response: TResponse | null;
  data(): TForm;
  transform(callback: UseFormTransformCallback<TForm>): this;
  defaults(): this;
  defaults<T extends FormDataKeys<TForm>>(field: T, value: FormDataValues<TForm, T>): this;
  defaults(fields: Partial<TForm>): this;
  reset<K extends FormDataKeys<TForm>>(...fields: K[]): this;
  clearErrors<K extends FormDataKeys<TForm>>(...fields: K[]): this;
  resetAndClearErrors<K extends FormDataKeys<TForm>>(...fields: K[]): this;
  setError<K extends FormDataKeys<TForm>>(field: K, value: ErrorValue): this;
  setError(errors: FormDataErrors<TForm>): this;
  submit(...args: UseHttpSubmitArguments<TResponse, TForm>): Promise<TResponse>;
  get(url: string, options?: UseHttpSubmitOptions<TResponse, TForm>): Promise<TResponse>;
  post(url: string, options?: UseHttpSubmitOptions<TResponse, TForm>): Promise<TResponse>;
  put(url: string, options?: UseHttpSubmitOptions<TResponse, TForm>): Promise<TResponse>;
  patch(url: string, options?: UseHttpSubmitOptions<TResponse, TForm>): Promise<TResponse>;
  delete(url: string, options?: UseHttpSubmitOptions<TResponse, TForm>): Promise<TResponse>;
  cancel(): void;
  dontRemember<K extends FormDataKeys<TForm>>(...fields: K[]): this;
  optimistic(callback: (currentData: TForm) => Partial<TForm>): this;
  withAllErrors(): this;
  withPrecognition(...args: UseFormWithPrecognitionArguments): UseHttpPrecognitiveProps<TForm, TResponse>;
}

export interface UseHttpValidationProps<TForm extends object> {
  invalid<K extends FormDataKeys<TForm>>(field: K): boolean;
  setValidationTimeout(duration: number): this;
  touch<K extends FormDataKeys<TForm>>(field: K | NamedInputEvent | Array<K>, ...fields: K[]): this;
  touched<K extends FormDataKeys<TForm>>(field?: K): boolean;
  valid<K extends FormDataKeys<TForm>>(field: K): boolean;
  validate<K extends FormDataKeys<TForm>>(
    field?: K | NamedInputEvent | PrecognitionValidationConfig<K>,
    config?: PrecognitionValidationConfig<K>
  ): this;
  validateFiles(): this;
  validating: boolean;
  validator: () => Validator;
  withAllErrors(): this;
  withoutFileValidation(): this;
  setErrors(errors: FormDataErrors<TForm> | Record<string, string | string[]>): this;
  forgetError<K extends FormDataKeys<TForm> | NamedInputEvent>(field: K): this;
}

interface InternalPrecognitionState {
  __touched: string[];
  __valid: string[];
}

export type UseHttp<TForm extends object, TResponse = unknown> = TForm & UseHttpProps<TForm, TResponse>;
export type UseHttpPrecognitiveProps<TForm extends object, TResponse = unknown> =
  UseHttp<TForm, TResponse> & UseHttpValidationProps<TForm> & InternalPrecognitionState;

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
 * v3's useHttp natively supports UrlMethodPair as first arg.
 * Vue's return type is reactive — we never spread it.
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
 * @example
 * ```ts
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

  if (
    !submitRoute ||
    (submitRoute.url === validationRoute.url && submitRoute.method === validationRoute.method)
  ) {
    return http;
  }

  // Different submit route: wrap submit to use the submission endpoint
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
