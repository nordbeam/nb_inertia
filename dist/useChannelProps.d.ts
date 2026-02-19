import { Socket } from 'phoenix';

/**
 * Append item to end of array
 */
export declare interface AppendStrategy<TItem, TEvent> {
    strategy: 'append';
    transform: (event: TEvent) => TItem;
}

/**
 * Options for useChannel hook
 */
declare interface ChannelOptions {
    /** Parameters to send when joining the channel */
    params?: Record<string, unknown>;
    /** Callback when channel join succeeds */
    onJoin?: (response: unknown) => void;
    /** Callback when channel join fails */
    onError?: (error: unknown) => void;
    /** Callback when channel is closed */
    onClose?: () => void;
    /** Whether the channel should be enabled (default: true) */
    enabled?: boolean;
}

/**
 * Custom event handler with helpers
 */
export declare type CustomEventHandler<TProps, TEvent> = (event: TEvent, helpers: {
    props: TProps;
    setProp: UseRealtimePropsReturn<TProps>['setProp'];
    setProps: UseRealtimePropsReturn<TProps>['setProps'];
    reload: UseRealtimePropsReturn<TProps>['reload'];
}) => void;

/**
 * Declarative event configuration
 */
export declare interface DeclarativeEventConfig<TProps, TItem, TEvent> {
    prop: keyof TProps;
    strategy: UpdateStrategy<TItem, TEvent>['strategy'];
    transform?: (event: TEvent) => TItem;
    match?: (item: TItem, event: TEvent) => boolean;
    key?: keyof TItem;
    only?: string[];
}

/**
 * Event configuration - either declarative or custom handler
 */
export declare type EventConfig<TProps extends Record<string, unknown>, TEvent> = DeclarativeEventConfig<TProps, unknown, TEvent> | CustomEventHandler<TProps, TEvent>;

/**
 * Map of event names to their configurations
 */
export declare type EventConfigs<TProps extends Record<string, unknown>, TEvents extends Record<string, unknown>> = {
    [K in keyof TEvents]?: EventConfig<TProps, TEvents[K]>;
};

/**
 * Prepend item to start of array
 */
export declare interface PrependStrategy<TItem, TEvent> {
    strategy: 'prepend';
    transform: (event: TEvent) => TItem;
}

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
/**
 * Reload options for useRealtimeProps
 */
declare interface ReloadOptions {
    /** Only reload these specific props */
    only?: string[];
    /** Preserve scroll position */
    preserveScroll?: boolean;
    /** Preserve component state */
    preserveState?: boolean;
}

/**
 * Reload prop(s) from server
 */
export declare interface ReloadStrategy {
    strategy: 'reload';
    only?: string[];
}

/**
 * Remove items matching predicate
 */
export declare interface RemoveStrategy<TItem, TEvent> {
    strategy: 'remove';
    match: (item: TItem, event: TEvent) => boolean;
}

/**
 * Replace entire prop value
 */
export declare interface ReplaceStrategy<TEvent> {
    strategy: 'replace';
    transform: (event: TEvent) => unknown;
}

/**
 * Built-in update strategies for prop arrays
 */
export declare type UpdateStrategy<TItem, TEvent> = AppendStrategy<TItem, TEvent> | PrependStrategy<TItem, TEvent> | RemoveStrategy<TItem, TEvent> | UpdateStrategy_<TItem, TEvent> | UpsertStrategy<TItem, TEvent> | ReplaceStrategy<TEvent> | ReloadStrategy;

/**
 * Update item in place by key
 */
export declare interface UpdateStrategy_<TItem, TEvent> {
    strategy: 'update';
    key: keyof TItem;
    transform: (event: TEvent) => TItem;
}

/**
 * Update if exists, append if not
 */
export declare interface UpsertStrategy<TItem, TEvent> {
    strategy: 'upsert';
    key: keyof TItem;
    transform: (event: TEvent) => TItem;
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
declare function useChannelProps<TProps extends Record<string, unknown> = Record<string, unknown>, TEvents extends Record<string, unknown> = Record<string, unknown>>(socket: Socket | null, topic: string, configs: EventConfigs<TProps, TEvents>, options?: ChannelOptions): UseChannelPropsReturn<TProps>;
export default useChannelProps;
export { useChannelProps }

/**
 * Return type for useChannelProps hook
 */
export declare interface UseChannelPropsReturn<T extends Record<string, unknown>> extends UseRealtimePropsReturn<T> {
}

/**
 * Return type for useRealtimeProps hook
 */
declare interface UseRealtimePropsReturn<T extends Record<string, unknown>> {
    /** Current props (server + optimistic updates) */
    props: T;
    /** Update a single prop */
    setProp: <K extends keyof T>(key: K, updater: T[K] | ((current: T[K]) => T[K])) => void;
    /** Update multiple props */
    setProps: (updater: Partial<T> | ((current: T) => Partial<T>)) => void;
    /** Reload props from server */
    reload: (options?: ReloadOptions) => void;
    /** Reset optimistic updates */
    resetOptimistic: () => void;
    /** Check if there are optimistic updates */
    hasOptimisticUpdates: boolean;
}

export { }
