import { FormDataType } from '@inertiajs/core';
import { InertiaFormProps } from '@inertiajs/react';
import { InertiaPrecognitiveFormProps } from '@inertiajs/react';
import { Method } from '@inertiajs/core';
import { UrlMethodPair } from '@inertiajs/core';

declare type FormDataArgument<TForm> = TForm | (() => TForm);

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
export declare function isRouteResult(value: unknown): value is RouteResult;

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

/**
 * Create standard form with no initial data.
 */
declare function useForm<TForm extends FormDataType<TForm>>(): InertiaFormProps<TForm>;

/**
 * Create standard form with inline or lazy initial data.
 */
declare function useForm<TForm extends FormDataType<TForm>>(data: FormDataArgument<TForm>): InertiaFormProps<TForm>;

/**
 * Create standard form with remember key support.
 */
declare function useForm<TForm extends FormDataType<TForm>>(rememberKey: string, data: FormDataArgument<TForm>): InertiaFormProps<TForm>;

/**
 * Create a precognitive form from explicit method, URL, and data.
 */
declare function useForm<TForm extends FormDataType<TForm>>(method: Method | (() => Method), url: string | (() => string), data: FormDataArgument<TForm>): InertiaPrecognitiveFormProps<TForm>;

/**
 * Create a precognitive form from a route result or lazy route resolver.
 */
declare function useForm<TForm extends FormDataType<TForm>>(route: UrlMethodPair | RouteResolver, data: FormDataArgument<TForm>): InertiaPrecognitiveFormProps<TForm>;

/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
declare function useForm<TForm extends FormDataType<TForm>>(data: FormDataArgument<TForm>, route: RouteLike): InertiaPrecognitiveFormProps<TForm>;
export default useForm;
export { useForm }

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
export declare function useFormWithPrecognition<TForm extends FormDataType<TForm>>(data: FormDataArgument<TForm>, validationRoute: RouteResult, submitRoute?: RouteResult): InertiaPrecognitiveFormProps<TForm>;

export { }
