import { router } from '@inertiajs/react';
import { useEffect, useRef } from 'react';
import type { FlashData } from './useFlash';

/**
 * Flash event detail structure from Inertia.
 */
export interface FlashEventDetail<T = FlashData> {
  flash: T;
}

/**
 * Callback function for flash events.
 */
export type OnFlashCallback<T = FlashData> = (flash: T) => void;

/**
 * Hook to listen for Inertia flash events.
 *
 * This hook registers a listener for the `flash` event that fires when
 * flash data is received. The listener is automatically cleaned up when
 * the component unmounts.
 *
 * @param callback - Function called with flash data when a flash event occurs
 *
 * @example
 * ```tsx
 * // Basic usage
 * function Layout({ children }) {
 *   useOnFlash(({ message }) => {
 *     if (message) {
 *       showToast(message);
 *     }
 *   });
 *
 *   return <div>{children}</div>;
 * }
 *
 * // With typed flash data
 * interface MyFlash {
 *   newUserId?: number;
 *   message?: string;
 * }
 *
 * function UserForm() {
 *   const [userId, setUserId] = useState<number | null>(null);
 *
 *   useOnFlash<MyFlash>(({ newUserId }) => {
 *     if (newUserId) {
 *       setUserId(newUserId);
 *     }
 *   });
 *
 *   return <form>...</form>;
 * }
 *
 * // Show toast notifications
 * function ToastHandler() {
 *   useOnFlash<{ toast?: { type: string; message: string } }>(({ toast }) => {
 *     if (toast) {
 *       showToast(toast.type, toast.message);
 *     }
 *   });
 *
 *   return null;
 * }
 * ```
 *
 * @remarks
 * - The flash event only fires when flash data has changed
 * - During partial reloads, it only fires if flash data differs from previous
 * - The callback receives the entire flash object, not individual values
 * - Register this in a persistent layout to avoid missing events
 */
export function useOnFlash<T extends FlashData = FlashData>(
  callback: OnFlashCallback<T>
): void {
  // Use ref to avoid re-registering listener when callback changes
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    // Listen for Inertia's flash event
    const removeListener = router.on('flash', (event) => {
      const detail = event.detail as FlashEventDetail<T>;
      callbackRef.current(detail.flash);
    });

    return removeListener;
  }, []);
}

export default useOnFlash;
