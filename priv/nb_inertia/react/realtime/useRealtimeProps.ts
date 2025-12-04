/**
 * NbInertia Realtime Props Hook for React
 *
 * Provides optimistic prop updates for Inertia.js pages with WebSocket integration.
 * Updates are instant and automatically sync with server state on navigation.
 *
 * @example
 * import { useRealtimeProps } from '@/lib/realtime';
 * import { useChannel } from '@/lib/socket';
 *
 * function ChatRoom() {
 *   const { props, setProp } = useRealtimeProps<ChatRoomProps>();
 *
 *   useChannel(socket, `chat:${props.room.id}`, {
 *     message_created: ({ message }) => {
 *       setProp('messages', msgs => [...msgs, message]);
 *     }
 *   });
 *
 *   return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
 * }
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { usePage, router } from '@inertiajs/react';

// ============================================================================
// Types
// ============================================================================

/**
 * Reload options for useRealtimeProps
 */
export interface ReloadOptions {
  /** Only reload these specific props */
  only?: string[];
  /** Preserve scroll position */
  preserveScroll?: boolean;
  /** Preserve component state */
  preserveState?: boolean;
}

/**
 * Return type for useRealtimeProps hook
 */
export interface UseRealtimePropsReturn<T extends Record<string, unknown>> {
  /** Current props (server + optimistic updates) */
  props: T;
  /** Update a single prop */
  setProp: <K extends keyof T>(
    key: K,
    updater: T[K] | ((current: T[K]) => T[K])
  ) => void;
  /** Update multiple props */
  setProps: (updater: Partial<T> | ((current: T) => Partial<T>)) => void;
  /** Reload props from server */
  reload: (options?: ReloadOptions) => void;
  /** Reset optimistic updates */
  resetOptimistic: () => void;
  /** Check if there are optimistic updates */
  hasOptimisticUpdates: boolean;
}

// ============================================================================
// useRealtimeProps Hook
// ============================================================================

/**
 * React hook for optimistic Inertia.js prop updates with WebSocket integration
 *
 * Provides instant local state updates that sync with server state on navigation
 * or manual reload. Perfect for real-time features via Phoenix Channels.
 *
 * ## How It Works
 *
 * 1. **Optimistic Updates**: `setProp` and `setProps` immediately update local state
 * 2. **Auto-Sync**: When Inertia navigates or reloads, optimistic state resets
 * 3. **Escape Hatch**: `reload()` fetches fresh data when needed
 *
 * @template T - Type for page props (from nb_ts)
 * @returns Object with props and update methods
 *
 * @example
 * // Basic usage
 * const { props, setProp } = useRealtimeProps<ChatRoomProps>();
 *
 * // Update a prop directly
 * setProp('unreadCount', 5);
 *
 * // Update with a function
 * setProp('messages', msgs => [...msgs, newMessage]);
 *
 * // Update multiple props
 * setProps({ unreadCount: 0, lastRead: Date.now() });
 *
 * @example
 * // With useChannel for WebSocket updates
 * const { props, setProp } = useRealtimeProps<ChatRoomProps>();
 *
 * useChannel(socket, `chat:${props.room.id}`, {
 *   message_created: ({ message }) => {
 *     setProp('messages', msgs => [...msgs, message]);
 *   },
 *   message_deleted: ({ id }) => {
 *     setProp('messages', msgs => msgs.filter(m => m.id !== id));
 *   }
 * });
 *
 * @example
 * // Reload from server
 * const { reload } = useRealtimeProps();
 *
 * // Reload specific props
 * reload({ only: ['messages'] });
 *
 * // Full reload
 * reload();
 */
export function useRealtimeProps<
  T extends Record<string, unknown> = Record<string, unknown>
>(): UseRealtimePropsReturn<T> {
  // Get server props from Inertia
  const { props: serverProps } = usePage<{ props: T }>();

  // Track optimistic updates separately
  const [optimistic, setOptimistic] = useState<Partial<T>>({});

  // Track server props identity to reset optimistic state on navigation
  const serverPropsId = useMemo(
    () => JSON.stringify(serverProps),
    [serverProps]
  );

  // Reset optimistic state when server props change (navigation, reload)
  useEffect(() => {
    setOptimistic({});
  }, [serverPropsId]);

  // Merge server and optimistic props
  const props = useMemo(
    () => ({ ...serverProps, ...optimistic }) as T,
    [serverProps, optimistic]
  );

  // Check if there are optimistic updates
  const hasOptimisticUpdates = useMemo(
    () => Object.keys(optimistic).length > 0,
    [optimistic]
  );

  // Update a single prop
  const setProp = useCallback(
    <K extends keyof T>(key: K, updater: T[K] | ((current: T[K]) => T[K])) => {
      setOptimistic((prev) => {
        const current = { ...serverProps, ...prev } as T;
        const newValue =
          typeof updater === 'function'
            ? (updater as (current: T[K]) => T[K])(current[key])
            : updater;
        return { ...prev, [key]: newValue };
      });
    },
    [serverProps]
  );

  // Update multiple props
  const setProps = useCallback(
    (updater: Partial<T> | ((current: T) => Partial<T>)) => {
      setOptimistic((prev) => {
        const current = { ...serverProps, ...prev } as T;
        const updates =
          typeof updater === 'function' ? updater(current) : updater;

        // Merge updates with existing optimistic state
        return { ...prev, ...updates };
      });
    },
    [serverProps]
  );

  // Reload props from server
  const reload = useCallback(
    (options: ReloadOptions = {}) => {
      router.reload({
        only: options.only,
        preserveScroll: options.preserveScroll ?? true,
        preserveState: options.preserveState ?? true,
        onSuccess: () => {
          setOptimistic({});
        },
      });
    },
    []
  );

  // Reset optimistic updates
  const resetOptimistic = useCallback(() => {
    setOptimistic({});
  }, []);

  return {
    props,
    setProp,
    setProps,
    reload,
    resetOptimistic,
    hasOptimisticUpdates,
  };
}

export default useRealtimeProps;
