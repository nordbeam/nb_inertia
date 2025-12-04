import { Socket } from 'phoenix';
import { ChannelOptions } from './socket';
import { UseRealtimePropsReturn } from './useRealtimeProps';
/**
 * Built-in update strategies for prop arrays
 */
export type UpdateStrategy<TItem, TEvent> = AppendStrategy<TItem, TEvent> | PrependStrategy<TItem, TEvent> | RemoveStrategy<TItem, TEvent> | UpdateStrategy_<TItem, TEvent> | UpsertStrategy<TItem, TEvent> | ReplaceStrategy<TEvent> | ReloadStrategy;
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
export type CustomEventHandler<TProps, TEvent> = (event: TEvent, helpers: {
    props: TProps;
    setProp: UseRealtimePropsReturn<TProps>['setProp'];
    setProps: UseRealtimePropsReturn<TProps>['setProps'];
    reload: UseRealtimePropsReturn<TProps>['reload'];
}) => void;
/**
 * Event configuration - either declarative or custom handler
 */
export type EventConfig<TProps extends Record<string, unknown>, TEvent> = DeclarativeEventConfig<TProps, unknown, TEvent> | CustomEventHandler<TProps, TEvent>;
/**
 * Map of event names to their configurations
 */
export type EventConfigs<TProps extends Record<string, unknown>, TEvents extends Record<string, unknown>> = {
    [K in keyof TEvents]?: EventConfig<TProps, TEvents[K]>;
};
/**
 * Return type for useChannelProps hook
 */
export interface UseChannelPropsReturn<T extends Record<string, unknown>> extends UseRealtimePropsReturn<T> {
}
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
export declare function useChannelProps<TProps extends Record<string, unknown> = Record<string, unknown>, TEvents extends Record<string, unknown> = Record<string, unknown>>(socket: Socket | null, topic: string, configs: EventConfigs<TProps, TEvents>, options?: ChannelOptions): UseChannelPropsReturn<TProps>;
export default useChannelProps;
//# sourceMappingURL=useChannelProps.d.ts.map