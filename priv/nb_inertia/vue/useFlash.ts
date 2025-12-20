import { usePage, router } from '@inertiajs/vue3';
import { computed, onMounted, onUnmounted, ref } from 'vue';

/**
 * Default flash data type.
 * Can be extended via TypeScript declaration merging.
 */
export interface FlashData {
  [key: string]: unknown;
}

export interface UseFlashResult<T extends FlashData = FlashData> {
  /**
   * Reactive flash data object
   */
  flash: T;

  /**
   * Check if a flash key exists and has a truthy value
   */
  has: (key: keyof T) => boolean;

  /**
   * Get a specific flash value with type safety
   */
  get: <K extends keyof T>(key: K) => T[K] | undefined;
}

/**
 * Composable for accessing Inertia flash data.
 *
 * Flash data is one-time data that doesn't persist in browser history,
 * ideal for success messages, newly created IDs, or other temporary values.
 *
 * @example
 * ```vue
 * <script setup lang="ts">
 * import { useFlash } from '@nordbeam/nb-inertia/vue';
 *
 * // Basic usage
 * const { flash, has, get } = useFlash();
 *
 * // With typed flash data
 * interface MyFlash {
 *   message?: string;
 *   toast?: { type: 'success' | 'error'; message: string };
 * }
 *
 * const { flash, has, get } = useFlash<MyFlash>();
 * </script>
 *
 * <template>
 *   <div v-if="has('message')" class="alert">
 *     {{ get('message') }}
 *   </div>
 *
 *   <div v-if="has('toast')" :class="['toast', get('toast')!.type]">
 *     {{ get('toast')!.message }}
 *   </div>
 * </template>
 * ```
 */
export function useFlash<T extends FlashData = FlashData>(): UseFlashResult<T> {
  const page = usePage<{ flash?: T }>();

  // Computed flash data
  const flash = computed(() => {
    return (page.props?.flash ?? {}) as T;
  });

  // Check if a key exists and has a truthy value
  const has = (key: keyof T): boolean => {
    const flashValue = flash.value;
    return flashValue != null && key in flashValue && !!flashValue[key];
  };

  // Get a specific value
  const get = <K extends keyof T>(key: K): T[K] | undefined => {
    return flash.value?.[key];
  };

  return { flash: flash.value, has, get };
}

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
 * Composable to listen for Inertia flash events.
 *
 * This composable registers a listener for the `flash` event that fires when
 * flash data is received. The listener is automatically cleaned up when
 * the component unmounts.
 *
 * @param callback - Function called with flash data when a flash event occurs
 *
 * @example
 * ```vue
 * <script setup lang="ts">
 * import { useOnFlash } from '@nordbeam/nb-inertia/vue';
 *
 * // Basic usage
 * useOnFlash(({ message }) => {
 *   if (message) {
 *     showToast(message);
 *   }
 * });
 *
 * // With typed flash data
 * interface MyFlash {
 *   newUserId?: number;
 * }
 *
 * const userId = ref<number | null>(null);
 *
 * useOnFlash<MyFlash>(({ newUserId }) => {
 *   if (newUserId) {
 *     userId.value = newUserId;
 *   }
 * });
 * </script>
 * ```
 */
export function useOnFlash<T extends FlashData = FlashData>(
  callback: OnFlashCallback<T>
): void {
  const removeListener = ref<(() => void) | null>(null);

  onMounted(() => {
    removeListener.value = router.on('flash', (event) => {
      const detail = (event as { detail: FlashEventDetail<T> }).detail;
      callback(detail.flash);
    });
  });

  onUnmounted(() => {
    if (removeListener.value) {
      removeListener.value();
    }
  });
}

export default useFlash;
