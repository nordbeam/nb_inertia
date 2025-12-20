import { usePage } from '@inertiajs/react';
import { useCallback, useMemo } from 'react';

/**
 * Default flash data type.
 * Can be extended via TypeScript declaration merging.
 */
export interface FlashData {
  [key: string]: unknown;
}

export interface UseFlashResult<T extends FlashData = FlashData> {
  /**
   * The complete flash data object
   */
  flash: T;

  /**
   * Check if a flash key exists and has a truthy value
   */
  has: <K extends keyof T>(key: K) => boolean;

  /**
   * Get a specific flash value with type safety
   */
  get: <K extends keyof T>(key: K) => T[K] | undefined;
}

/**
 * Hook for accessing Inertia flash data.
 *
 * Flash data is one-time data that doesn't persist in browser history,
 * ideal for success messages, newly created IDs, or other temporary values.
 *
 * @example
 * ```tsx
 * // Basic usage
 * function Layout({ children }) {
 *   const { flash, has, get } = useFlash();
 *
 *   return (
 *     <div>
 *       {has('message') && <Toast>{get('message')}</Toast>}
 *       {children}
 *     </div>
 *   );
 * }
 *
 * // With typed flash data
 * interface MyFlash {
 *   message?: string;
 *   toast?: { type: 'success' | 'error'; message: string };
 *   newUserId?: number;
 * }
 *
 * function Dashboard() {
 *   const { flash, has, get } = useFlash<MyFlash>();
 *
 *   useEffect(() => {
 *     if (has('newUserId')) {
 *       console.log('New user ID:', get('newUserId'));
 *     }
 *   }, [flash]);
 *
 *   return (
 *     <div>
 *       {has('toast') && (
 *         <Toast type={get('toast')!.type}>
 *           {get('toast')!.message}
 *         </Toast>
 *       )}
 *     </div>
 *   );
 * }
 * ```
 */
export function useFlash<T extends FlashData = FlashData>(): UseFlashResult<T> {
  const page = usePage<{ flash?: T }>();

  // Memoize flash to prevent unnecessary re-renders
  const flash = useMemo(() => {
    return (page.props?.flash ?? {}) as T;
  }, [page.props?.flash]);

  // Check if a key exists and has a truthy value
  const has = useCallback(
    <K extends keyof T>(key: K): boolean => {
      return flash != null && key in flash && !!flash[key];
    },
    [flash]
  );

  // Get a specific value
  const get = useCallback(
    <K extends keyof T>(key: K): T[K] | undefined => {
      return flash?.[key];
    },
    [flash]
  );

  return { flash, has, get };
}

export default useFlash;
