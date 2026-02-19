/**
 * Default flash data type.
 * Can be extended via TypeScript declaration merging.
 */
export declare interface FlashData {
    [key: string]: unknown;
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
declare function useFlash<T extends FlashData = FlashData>(): UseFlashResult<T>;
export default useFlash;
export { useFlash }

export declare interface UseFlashResult<T extends FlashData = FlashData> {
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

export { }
