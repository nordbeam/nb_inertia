import { FormDataType, Method, UrlMethodPair } from '@inertiajs/core';
import { InertiaFormProps, InertiaPrecognitiveFormProps } from '@inertiajs/react';
import { RouteResult } from '../shared/types';
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';
type FormDataArgument<TForm> = TForm | (() => TForm);
type RouteResolver = () => UrlMethodPair;
type RouteLike = RouteResult | RouteResolver;
/**
 * Create standard form with no initial data.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(): InertiaFormProps<TForm>;
/**
 * Create standard form with inline or lazy initial data.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(data: FormDataArgument<TForm>): InertiaFormProps<TForm>;
/**
 * Create standard form with remember key support.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(rememberKey: string, data: FormDataArgument<TForm>): InertiaFormProps<TForm>;
/**
 * Create a precognitive form from explicit method, URL, and data.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(method: Method | (() => Method), url: string | (() => string), data: FormDataArgument<TForm>): InertiaPrecognitiveFormProps<TForm>;
/**
 * Create a precognitive form from a route result or lazy route resolver.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(route: UrlMethodPair | RouteResolver, data: FormDataArgument<TForm>): InertiaPrecognitiveFormProps<TForm>;
/**
 * Convenience overload that preserves nb_inertia's historic data-first route binding API.
 */
export declare function useForm<TForm extends FormDataType<TForm>>(data: FormDataArgument<TForm>, route: RouteLike): InertiaPrecognitiveFormProps<TForm>;
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
export default useForm;
//# sourceMappingURL=useForm.d.ts.map