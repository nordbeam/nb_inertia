import { ErrorValue } from '@inertiajs/core';
import { FormDataErrors } from '@inertiajs/core';
import { FormDataKeys } from '@inertiajs/core';
import { FormDataType } from '@inertiajs/core';
import { FormDataValues } from '@inertiajs/core';
import { Method } from '@inertiajs/core';
import { NamedInputEvent } from 'laravel-precognition';
import { Progress } from '@inertiajs/core';
import { UrlMethodPair } from '@inertiajs/core';
import { UseFormTransformCallback } from '@inertiajs/core';
import { UseFormWithPrecognitionArguments } from '@inertiajs/core';
import { UseHttpSubmitArguments } from '@inertiajs/core';
import { UseHttpSubmitOptions } from '@inertiajs/core';
import { ValidationConfig } from 'laravel-precognition';
import { Validator } from 'laravel-precognition';

declare type FormDataArgument<TForm> = TForm | (() => TForm);

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
export declare function isRouteResult(value: unknown): value is RouteResult;

declare type PrecognitionValidationConfig<TKeys> = ValidationConfig & {
    only?: TKeys[] | Iterable<TKeys> | ArrayLike<TKeys>;
};

declare type RouteLike = RouteResult | RouteResolver;

declare type RouteResolver = () => UrlMethodPair;

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
    method: 'get' | 'post' | 'put' | 'patch' | 'delete';
    component?: string | Record<string, string>;
};

declare type SetDataAction<TForm> = SetDataByObject<TForm> & SetDataByMethod<TForm> & SetDataByKeyValuePair<TForm>;

declare type SetDataByKeyValuePair<TForm> = <K extends FormDataKeys<TForm>>(key: K, value: FormDataValues<TForm, K>) => void;

declare type SetDataByMethod<TForm> = (data: (previousData: TForm) => TForm) => void;

declare type SetDataByObject<TForm> = (data: TForm) => void;

export declare type UseHttp<TForm extends object, TResponse = unknown> = UseHttpProps<TForm, TResponse>;

/**
 * Create standard request with no initial data.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(): UseHttp<TForm, TResponse>;

/**
 * Create standard request with inline or lazy initial data.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(data: FormDataArgument<TForm>): UseHttp<TForm, TResponse>;

/**
 * Create standard request with remember key support.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(rememberKey: string, data: FormDataArgument<TForm>): UseHttp<TForm, TResponse>;

/**
 * Create a precognitive request from explicit method, URL, and data.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(method: Method | (() => Method), url: string | (() => string), data: FormDataArgument<TForm>): UseHttpPrecognitiveProps<TForm, TResponse>;

/**
 * Create a precognitive request from a route result or lazy route resolver.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(route: UrlMethodPair | RouteResolver, data: FormDataArgument<TForm>): UseHttpPrecognitiveProps<TForm, TResponse>;

/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
declare function useHttp<TForm extends FormDataType<TForm>, TResponse = unknown>(data: FormDataArgument<TForm>, route: RouteLike): UseHttpPrecognitiveProps<TForm, TResponse>;
export default useHttp;
export { useHttp }

export declare type UseHttpPrecognitiveProps<TForm extends object, TResponse = unknown> = UseHttpProps<TForm, TResponse> & UseHttpValidationProps<TForm, TResponse>;

export declare interface UseHttpProps<TForm extends object, TResponse = unknown> {
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

export declare interface UseHttpValidationProps<TForm extends object, TResponse = unknown> {
    invalid: <K extends FormDataKeys<TForm>>(field: K) => boolean;
    setValidationTimeout: (duration: number) => UseHttpPrecognitiveProps<TForm, TResponse>;
    touch: <K extends FormDataKeys<TForm>>(field: K | NamedInputEvent | Array<K>, ...fields: K[]) => UseHttpPrecognitiveProps<TForm, TResponse>;
    touched: <K extends FormDataKeys<TForm>>(field?: K) => boolean;
    valid: <K extends FormDataKeys<TForm>>(field: K) => boolean;
    validate: <K extends FormDataKeys<TForm>>(field?: K | NamedInputEvent | PrecognitionValidationConfig<K>, config?: PrecognitionValidationConfig<K>) => UseHttpPrecognitiveProps<TForm, TResponse>;
    validateFiles: () => UseHttpPrecognitiveProps<TForm, TResponse>;
    validating: boolean;
    validator: () => Validator;
    withAllErrors: () => UseHttpPrecognitiveProps<TForm, TResponse>;
    withoutFileValidation: () => UseHttpPrecognitiveProps<TForm, TResponse>;
    setErrors: (errors: FormDataErrors<TForm>) => UseHttpPrecognitiveProps<TForm, TResponse>;
    forgetError: <K extends FormDataKeys<TForm> | NamedInputEvent>(field: K) => UseHttpPrecognitiveProps<TForm, TResponse>;
}

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
export declare function useHttpWithPrecognition<TForm extends FormDataType<TForm>, TResponse = unknown>(data: FormDataArgument<TForm>, validationRoute: RouteResult, submitRoute?: RouteResult): UseHttpPrecognitiveProps<TForm, TResponse>;

export { }
