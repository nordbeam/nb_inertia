/**
 * NbInertia Enhanced useForm Hook for React with Precognition Support
 *
 * Provides an enhanced Inertia.js useForm hook that supports:
 * 1. Route binding via RouteResult from nb_routes
 * 2. Precognition for real-time validation (via official Inertia.js v2.3+)
 * 3. RouteResult objects for validation endpoints
 *
 * @example Basic route binding (no Precognition)
 * ```tsx
 * import { useForm } from '@nordbeam/nb-inertia/react/useForm';
 * import { update_user_path } from '@/routes';
 *
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * form.submit(); // Automatically uses PATCH /users/1
 * ```
 *
 * @example With Precognition using RouteResult
 * ```tsx
 * import { useForm } from '@nordbeam/nb-inertia/react/useForm';
 * import { store_user_path } from '@/routes';
 *
 * const form = useForm({ name: '', email: '' })
 *   .withPrecognition(store_user_path.post());
 *
 * // Validate on blur
 * <input
 *   value={form.data.name}
 *   onChange={e => form.setData('name', e.target.value)}
 *   onBlur={() => form.validate('name')}
 * />
 * {form.invalid('name') && <span>{form.errors.name}</span>}
 * {form.validating && <span>Validating...</span>}
 * ```
 *
 * @example Shorthand: Precognition at creation time
 * ```tsx
 * // Same endpoint for validation and submission
 * const form = useForm(store_user_path.post(), { name: '', email: '' });
 * form.validate('email'); // Validates against POST /users
 * form.submit(); // Submits to POST /users
 * ```
 */

import { useForm as useInertiaForm } from '@inertiajs/react';
import type {
  InertiaFormProps as InertiaFormPropsBase,
  InertiaPrecognitiveFormProps as InertiaPrecognitiveFormPropsBase,
} from '@inertiajs/react';
import { type RouteResult, isRouteResult } from '../shared/types';

// Re-export RouteResult and type guard for convenience
export type { RouteResult } from '../shared/types';
export { isRouteResult } from '../shared/types';

/**
 * HTTP methods supported by forms
 */
export type Method = 'get' | 'post' | 'put' | 'patch' | 'delete';

/**
 * Submit options when form is bound to a route
 */
export type BoundSubmitOptions = Omit<Parameters<ReturnType<typeof useInertiaForm>['submit']>[2], never>;

/**
 * Arguments for withPrecognition method
 * Supports: (method, url) | (RouteResult) | (() => RouteResult)
 */
export type WithPrecognitionArgs =
  | [Method | (() => Method), string | (() => string)]
  | [RouteResult | (() => RouteResult)];

/**
 * Form type when NOT bound to a route (standard Inertia form)
 */
export type UnboundFormType<TForm extends object> = ReturnType<typeof useInertiaForm<TForm>>;

/**
 * Form type when bound to a route
 * - submit() takes no method/url arguments
 * - All other methods work the same
 */
export type BoundFormType<TForm extends object> = Omit<UnboundFormType<TForm>, 'submit'> & {
  /**
   * Submit the form using the bound route's URL and method
   * @param options - Optional visit options (preserveState, preserveScroll, etc.)
   */
  submit(options?: BoundSubmitOptions): void;
};

/**
 * Form type with Precognition enabled (has validation methods)
 * This matches the official Inertia Precognitive form type
 */
export type PrecognitiveFormType<TForm extends object> = InertiaPrecognitiveFormPropsBase<TForm>;

/**
 * Form type with both route binding AND Precognition
 * - submit() uses bound route
 * - Has all validation methods (validate, touch, invalid, valid, etc.)
 */
export type BoundPrecognitiveFormType<TForm extends object> = Omit<PrecognitiveFormType<TForm>, 'submit'> & {
  /**
   * Submit the form using the bound route's URL and method
   * @param options - Optional visit options
   */
  submit(options?: BoundSubmitOptions): void;
};

// ============================================================================
// Overload signatures for useForm
// ============================================================================

/**
 * Create form with Precognition enabled at creation time using RouteResult
 *
 * @example
 * ```tsx
 * const form = useForm(store_user_path.post(), { name: '', email: '' });
 * form.validate('email');
 * form.submit(); // Uses POST /users
 * ```
 */
export function useForm<TForm extends Record<string, any>>(
  route: RouteResult,
  data: TForm
): BoundPrecognitiveFormType<TForm>;

/**
 * Create form with route binding (no Precognition)
 *
 * @example
 * ```tsx
 * const form = useForm({ name: '' }, update_user_path.patch(1));
 * form.submit(); // Uses PATCH /users/1
 * ```
 */
export function useForm<TForm extends Record<string, any>>(
  data: TForm,
  route: RouteResult
): BoundFormType<TForm>;

/**
 * Create standard form (no binding, no Precognition)
 *
 * @example
 * ```tsx
 * const form = useForm({ name: '' });
 * form.submit('post', '/users');
 *
 * // Or enable Precognition later:
 * const precogForm = form.withPrecognition('post', '/validate');
 * ```
 */
export function useForm<TForm extends Record<string, any>>(
  data: TForm
): UnboundFormType<TForm>;

/**
 * Implementation
 */
export function useForm<TForm extends Record<string, any>>(
  dataOrRoute: TForm | RouteResult,
  routeOrData?: RouteResult | TForm
): UnboundFormType<TForm> | BoundFormType<TForm> | BoundPrecognitiveFormType<TForm> {
  // Determine which overload was called
  const isPrecognitionShorthand = isRouteResult(dataOrRoute);
  const isRouteBinding = routeOrData !== undefined && isRouteResult(routeOrData);

  // Extract data and route based on call pattern
  let data: TForm;
  let submitRoute: RouteResult | undefined;
  let precognitionRoute: RouteResult | undefined;

  if (isPrecognitionShorthand) {
    // Pattern: useForm(route, data) - Precognition shorthand
    // Route is used for BOTH validation AND submission
    precognitionRoute = dataOrRoute as RouteResult;
    submitRoute = dataOrRoute as RouteResult;
    data = routeOrData as TForm;
  } else if (isRouteBinding) {
    // Pattern: useForm(data, route) - Route binding only
    data = dataOrRoute as TForm;
    submitRoute = routeOrData as RouteResult;
  } else {
    // Pattern: useForm(data) - Standard form
    data = dataOrRoute as TForm;
  }

  // Create the base Inertia form
  // If we have a precognition route, pass it in the Inertia-compatible format
  let inertiaForm: ReturnType<typeof useInertiaForm<TForm>>;

  if (precognitionRoute) {
    // Use Inertia's built-in Precognition by passing (method, url, data)
    // This is the official Inertia v2.3+ pattern
    inertiaForm = useInertiaForm<TForm>(
      precognitionRoute.method as Method,
      precognitionRoute.url,
      data
    );
  } else {
    // Standard form without Precognition at creation time
    inertiaForm = useInertiaForm<TForm>(data);
  }

  // If no submit route binding needed, return as-is (with or without Precognition)
  if (!submitRoute) {
    return inertiaForm;
  }

  // Create bound form with enhanced submit
  const boundSubmit = (options?: BoundSubmitOptions) => {
    return inertiaForm.submit(submitRoute!.method as Method, submitRoute!.url, options);
  };

  // For Precognition shorthand, the form already has validation methods
  // We just need to override submit
  if (precognitionRoute) {
    // Form has Precognition methods, override submit for route binding
    return {
      ...inertiaForm,
      submit: boundSubmit,
    } as BoundPrecognitiveFormType<TForm>;
  }

  // Route binding only (no Precognition)
  return {
    ...inertiaForm,
    submit: boundSubmit,
  } as BoundFormType<TForm>;
}

// ============================================================================
// Helper: Enhance withPrecognition to accept RouteResult
// ============================================================================

/**
 * Create an enhanced form with Precognition that accepts RouteResult
 *
 * This is useful when you want to add Precognition to an existing form
 * or when you want different validation and submission endpoints.
 *
 * @example
 * ```tsx
 * import { useFormWithPrecognition } from '@nordbeam/nb-inertia/react/useForm';
 * import { validate_user_path, store_user_path } from '@/routes';
 *
 * // Different validation and submission endpoints
 * const form = useFormWithPrecognition(
 *   { name: '', email: '' },
 *   validate_user_path.post(),   // Validation endpoint
 *   store_user_path.post()       // Submission endpoint
 * );
 * ```
 */
export function useFormWithPrecognition<TForm extends Record<string, any>>(
  data: TForm,
  validationRoute: RouteResult,
  submitRoute?: RouteResult
): BoundPrecognitiveFormType<TForm> | PrecognitiveFormType<TForm> {
  // Create form with Precognition enabled
  const inertiaForm = useInertiaForm<TForm>(
    validationRoute.method as Method,
    validationRoute.url,
    data
  );

  // If no separate submit route, return as-is
  if (!submitRoute) {
    return inertiaForm as PrecognitiveFormType<TForm>;
  }

  // Override submit to use the submit route
  const boundSubmit = (options?: BoundSubmitOptions) => {
    return inertiaForm.submit(submitRoute.method as Method, submitRoute.url, options);
  };

  return {
    ...inertiaForm,
    submit: boundSubmit,
  } as BoundPrecognitiveFormType<TForm>;
}

export default useForm;
