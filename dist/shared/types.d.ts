/**
 * Shared types and utilities for nb_inertia
 *
 * This module provides common types and utilities used across React and Vue components.
 */
/**
 * Base flash data type.
 *
 * Flash data is one-time data that doesn't persist in browser history.
 * Unlike regular props, flash values are cleared after being sent.
 *
 * @example
 * ```ts
 * // Extend via declaration merging for type-safe flash access
 * declare module '@nordbeam/nb-inertia/shared/types' {
 *   interface FlashData {
 *     message?: string;
 *     toast?: {
 *       type: 'success' | 'error';
 *       message: string;
 *     };
 *     newUserId?: number;
 *   }
 * }
 * ```
 */
export interface FlashData {
    [key: string]: unknown;
}
/**
 * Page object with flash as a top-level field.
 *
 * This extends the standard Inertia page object with a flash field
 * that contains one-time data.
 */
export interface PageWithFlash<TProps = Record<string, unknown>> {
    component: string;
    props: TProps;
    url: string;
    version: string;
    flash: FlashData;
    encryptHistory?: boolean;
    clearHistory?: boolean;
    mergeProps?: string[];
    deepMergeProps?: string[];
    deferredProps?: Record<string, string[]>;
    onceProps?: Record<string, {
        prop: string;
        expiresAt?: number;
    }>;
}
/**
 * RouteResult type from nb_routes rich mode
 *
 * Rich mode route helpers return objects with both url and method,
 * allowing components to automatically use the correct HTTP method.
 *
 * NOTE: This type matches @inertiajs/core's UrlMethodPair type exactly.
 * The official Inertia.js router and Link components already support this pattern.
 */
export type RouteResult = {
    url: string;
    method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
};
/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
export declare function isRouteResult(value: unknown): value is RouteResult;
//# sourceMappingURL=types.d.ts.map