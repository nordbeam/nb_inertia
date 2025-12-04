/**
 * NbInertia Combined Channel + Props Hook for React
 *
 * Provides a declarative way to connect Phoenix Channel events to Inertia prop updates.
 * Supports both custom handlers and built-in update strategies.
 *
 * @example
 * import { useChannelProps } from '@/lib/realtime';
 *
 * function ChatRoom() {
 *   const { props } = useChannelProps<ChatRoomProps, ChatEvents>(
 *     socket,
 *     `chat:${initialRoom.id}`,
 *     {
 *       message_created: { prop: 'messages', strategy: 'append', transform: e => e.message },
 *       message_deleted: { prop: 'messages', strategy: 'remove', match: (m, e) => m.id === e.id },
 *     }
 *   );
 *
 *   return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
 * }
 */

import { useMemo } from 'react';
import { Socket } from 'phoenix';
import { useChannel, type ChannelOptions, type EventHandlers } from './socket';
import { useRealtimeProps, type UseRealtimePropsReturn, type ReloadOptions } from './useRealtimeProps';

// ============================================================================
// Types
// ============================================================================

/**
 * Built-in update strategies for prop arrays
 */
export type UpdateStrategy<TItem, TEvent> =
  | AppendStrategy<TItem, TEvent>
  | PrependStrategy<TItem, TEvent>
  | RemoveStrategy<TItem, TEvent>
  | UpdateStrategy_<TItem, TEvent>
  | UpsertStrategy<TItem, TEvent>
  | ReplaceStrategy<TEvent>
  | ReloadStrategy;

/**
 * Append item to end of array
 */
export interface AppendStrategy<TItem, TEvent> {
  strategy: 'append';
  transform: (event: TEvent) => TItem;
}

/**
 * Prepend item to start of array
 */
export interface PrependStrategy<TItem, TEvent> {
  strategy: 'prepend';
  transform: (event: TEvent) => TItem;
}

/**
 * Remove items matching predicate
 */
export interface RemoveStrategy<TItem, TEvent> {
  strategy: 'remove';
  match: (item: TItem, event: TEvent) => boolean;
}

/**
 * Update item in place by key
 */
export interface UpdateStrategy_<TItem, TEvent> {
  strategy: 'update';
  key: keyof TItem;
  transform: (event: TEvent) => TItem;
}

/**
 * Update if exists, append if not
 */
export interface UpsertStrategy<TItem, TEvent> {
  strategy: 'upsert';
  key: keyof TItem;
  transform: (event: TEvent) => TItem;
}

/**
 * Replace entire prop value
 */
export interface ReplaceStrategy<TEvent> {
  strategy: 'replace';
  transform: (event: TEvent) => unknown;
}

/**
 * Reload prop(s) from server
 */
export interface ReloadStrategy {
  strategy: 'reload';
  only?: string[];
}

/**
 * Declarative event configuration
 */
export interface DeclarativeEventConfig<TProps, TItem, TEvent> {
  prop: keyof TProps;
  strategy: UpdateStrategy<TItem, TEvent>['strategy'];
  transform?: (event: TEvent) => TItem;
  match?: (item: TItem, event: TEvent) => boolean;
  key?: keyof TItem;
  only?: string[];
}

/**
 * Custom event handler with helpers
 */
export type CustomEventHandler<TProps, TEvent> = (
  event: TEvent,
  helpers: {
    props: TProps;
    setProp: UseRealtimePropsReturn<TProps>['setProp'];
    setProps: UseRealtimePropsReturn<TProps>['setProps'];
    reload: UseRealtimePropsReturn<TProps>['reload'];
  }
) => void;

/**
 * Event configuration - either declarative or custom handler
 */
export type EventConfig<TProps extends Record<string, unknown>, TEvent> =
  | DeclarativeEventConfig<TProps, unknown, TEvent>
  | CustomEventHandler<TProps, TEvent>;

/**
 * Map of event names to their configurations
 */
export type EventConfigs<
  TProps extends Record<string, unknown>,
  TEvents extends Record<string, unknown>
> = {
  [K in keyof TEvents]?: EventConfig<TProps, TEvents[K]>;
};

/**
 * Return type for useChannelProps hook
 */
export interface UseChannelPropsReturn<T extends Record<string, unknown>>
  extends UseRealtimePropsReturn<T> {}

// ============================================================================
// useChannelProps Hook
// ============================================================================

/**
 * React hook combining Phoenix Channel subscription with Inertia prop updates
 *
 * Provides a declarative way to map channel events to prop updates using
 * built-in strategies (append, remove, update, etc.) or custom handlers.
 *
 * @template TProps - Type for page props (from nb_ts)
 * @template TEvents - Type for channel events
 * @param socket - Phoenix Socket instance
 * @param topic - Channel topic (e.g., "chat:123")
 * @param configs - Map of event names to configurations
 * @param options - Channel options (params, callbacks, enabled)
 * @returns Object with props and update methods
 *
 * @example
 * // Declarative strategies
 * const { props } = useChannelProps<ChatRoomProps, ChatEvents>(
 *   socket,
 *   `chat:${roomId}`,
 *   {
 *     // Append new message to array
 *     message_created: {
 *       prop: 'messages',
 *       strategy: 'append',
 *       transform: e => e.message
 *     },
 *
 *     // Remove message from array
 *     message_deleted: {
 *       prop: 'messages',
 *       strategy: 'remove',
 *       match: (msg, event) => msg.id === event.id
 *     },
 *
 *     // Update message in place
 *     message_edited: {
 *       prop: 'messages',
 *       strategy: 'update',
 *       key: 'id',
 *       transform: e => e.message
 *     },
 *
 *     // Upsert (update or append)
 *     user_status: {
 *       prop: 'users',
 *       strategy: 'upsert',
 *       key: 'id',
 *       transform: e => e.user
 *     },
 *
 *     // Replace entire prop
 *     room_updated: {
 *       prop: 'room',
 *       strategy: 'replace',
 *       transform: e => e.room
 *     },
 *
 *     // Reload from server
 *     major_change: {
 *       prop: 'messages',
 *       strategy: 'reload',
 *       only: ['messages', 'room']
 *     }
 *   }
 * );
 *
 * @example
 * // Custom handlers
 * const { props } = useChannelProps<ChatRoomProps, ChatEvents>(
 *   socket,
 *   `chat:${roomId}`,
 *   {
 *     // Declarative for simple cases
 *     message_created: {
 *       prop: 'messages',
 *       strategy: 'append',
 *       transform: e => e.message
 *     },
 *
 *     // Custom handler for complex logic
 *     presence_changed: (event, { props, setProp, reload }) => {
 *       if (event.userCount > 100) {
 *         // Too many users, fall back to polling
 *         reload({ only: ['messages'] });
 *       } else {
 *         setProp('onlineUsers', event.users);
 *       }
 *     }
 *   }
 * );
 */
export function useChannelProps<
  TProps extends Record<string, unknown> = Record<string, unknown>,
  TEvents extends Record<string, unknown> = Record<string, unknown>
>(
  socket: Socket | null,
  topic: string,
  configs: EventConfigs<TProps, TEvents>,
  options?: ChannelOptions
): UseChannelPropsReturn<TProps> {
  // Get props and update helpers
  const realtimeProps = useRealtimeProps<TProps>();
  const { props, setProp, setProps, reload } = realtimeProps;

  // Build event handlers from configs
  const handlers = useMemo(() => {
    const result: EventHandlers<TEvents> = {};

    for (const [eventName, config] of Object.entries(configs)) {
      if (!config) continue;

      // Custom handler function
      if (typeof config === 'function') {
        result[eventName as keyof TEvents] = ((event: TEvents[keyof TEvents]) => {
          (config as CustomEventHandler<TProps, TEvents[keyof TEvents]>)(event, {
            props,
            setProp,
            setProps,
            reload,
          });
        }) as (payload: TEvents[keyof TEvents]) => void;
        continue;
      }

      // Declarative config
      const declarativeConfig = config as DeclarativeEventConfig<TProps, unknown, TEvents[keyof TEvents]>;
      const { prop, strategy } = declarativeConfig;

      result[eventName as keyof TEvents] = ((event: TEvents[keyof TEvents]) => {
        switch (strategy) {
          case 'append':
            setProp(prop, ((arr: unknown[]) => [
              ...arr,
              declarativeConfig.transform!(event),
            ]) as TProps[typeof prop] | ((current: TProps[typeof prop]) => TProps[typeof prop]));
            break;

          case 'prepend':
            setProp(prop, ((arr: unknown[]) => [
              declarativeConfig.transform!(event),
              ...arr,
            ]) as TProps[typeof prop] | ((current: TProps[typeof prop]) => TProps[typeof prop]));
            break;

          case 'remove':
            setProp(prop, ((arr: unknown[]) =>
              arr.filter((item) => !declarativeConfig.match!(item, event))
            ) as TProps[typeof prop] | ((current: TProps[typeof prop]) => TProps[typeof prop]));
            break;

          case 'update':
            setProp(prop, ((arr: unknown[]) => {
              const updated = declarativeConfig.transform!(event);
              const key = declarativeConfig.key!;
              return arr.map((item) =>
                (item as Record<string, unknown>)[key as string] === (updated as Record<string, unknown>)[key as string]
                  ? updated
                  : item
              );
            }) as TProps[typeof prop] | ((current: TProps[typeof prop]) => TProps[typeof prop]));
            break;

          case 'upsert':
            setProp(prop, ((arr: unknown[]) => {
              const updated = declarativeConfig.transform!(event);
              const key = declarativeConfig.key!;
              const index = arr.findIndex(
                (item) => (item as Record<string, unknown>)[key as string] === (updated as Record<string, unknown>)[key as string]
              );
              if (index >= 0) {
                return arr.map((item, i) => (i === index ? updated : item));
              }
              return [...arr, updated];
            }) as TProps[typeof prop] | ((current: TProps[typeof prop]) => TProps[typeof prop]));
            break;

          case 'replace':
            setProp(prop, declarativeConfig.transform!(event) as TProps[typeof prop]);
            break;

          case 'reload':
            reload({ only: declarativeConfig.only });
            break;
        }
      }) as (payload: TEvents[keyof TEvents]) => void;
    }

    return result;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props, setProp, setProps, reload]);

  // Subscribe to channel
  useChannel<TEvents>(socket, topic, handlers, options);

  return realtimeProps;
}

export default useChannelProps;
