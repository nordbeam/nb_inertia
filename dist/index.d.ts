import { Channel } from 'phoenix';
import { Presence } from 'phoenix';
import { Socket } from 'phoenix';

/**
 * Append item to end of array
 */
export declare interface AppendStrategy<TItem, TEvent> {
    strategy: 'append';
    transform: (event: TEvent) => TItem;
}

export { Channel }

/**
 * Options for useChannel hook
 */
export declare interface ChannelOptions {
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
 * Creates a Phoenix Socket instance with sensible defaults
 *
 * @param endpoint - Socket endpoint URL (e.g., '/socket')
 * @param options - Socket configuration options
 * @returns Configured Socket instance
 *
 * @example
 * const socket = createSocket('/socket', {
 *   params: () => ({
 *     token: document.querySelector('meta[name="csrf-token"]')?.content
 *   })
 * });
 */
export declare function createSocket(endpoint: string, options?: SocketOptions): Socket;

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
 * Event handler function type
 */
export declare type EventHandler<T = unknown> = (payload: T) => void;

/**
 * Map of event names to their handlers
 */
export declare type EventHandlers<T extends Record<string, unknown> = Record<string, unknown>> = {
    [K in keyof T]?: EventHandler<T[K]>;
};

/**
 * Prepend item to start of array
 */
export declare interface PrependStrategy<TItem, TEvent> {
    strategy: 'prepend';
    transform: (event: TEvent) => TItem;
}

export { Presence }

/**
 * Options for usePresence hook
 */
export declare interface PresenceOptions extends ChannelOptions {
    /** Callback when presence syncs */
    onSync?: () => void;
    /** Callback when a user joins */
    onJoin?: (id: string, current: unknown, newPres: unknown) => void;
    /** Callback when a user leaves */
    onLeave?: (id: string, current: unknown, leftPres: unknown) => void;
}

/**
 * Presence state structure from Phoenix Presence
 */
export declare interface PresenceState<T = unknown> {
    [key: string]: {
        metas: T[];
    };
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
export declare interface ReloadOptions {
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

export { Socket }

/**
 * Socket configuration options
 */
export declare interface SocketOptions {
    /** Parameters to send with the socket connection */
    params?: (() => Record<string, unknown>) | Record<string, unknown>;
    /** Logger function for debugging */
    logger?: (kind: string, msg: string, data: unknown) => void;
    /** Reconnect after error delay in ms (default: 10000) */
    reconnectAfterMs?: (tries: number) => number;
    /** Heartbeat interval in ms (default: 30000) */
    heartbeatIntervalMs?: number;
}

/**
 * Update item in place by key
 */
export declare interface UpdateItemStrategy<TItem, TEvent> {
    strategy: 'update';
    key: keyof TItem;
    transform: (event: TEvent) => TItem;
}

/**
 * Built-in update strategies for prop arrays
 */
export declare type UpdateStrategy<TItem, TEvent> = AppendStrategy<TItem, TEvent> | PrependStrategy<TItem, TEvent> | RemoveStrategy<TItem, TEvent> | UpdateItemStrategy<TItem, TEvent> | UpsertStrategy<TItem, TEvent> | ReplaceStrategy<TEvent> | ReloadStrategy;

/**
 * Update if exists, append if not
 */
export declare interface UpsertStrategy<TItem, TEvent> {
    strategy: 'upsert';
    key: keyof TItem;
    transform: (event: TEvent) => TItem;
}

/**
 * React hook for subscribing to Phoenix Channels with automatic lifecycle management
 *
 * Handles channel join/leave on mount/unmount, and supports updating event handlers
 * without rejoining the channel.
 *
 * @template TEvents - Type for channel events (optional, for type safety)
 * @param socket - Phoenix Socket instance
 * @param topic - Channel topic (e.g., "chat:123")
 * @param handlers - Map of event names to handler functions
 * @param options - Channel options (params, callbacks, enabled)
 * @returns The Channel instance (or null if not connected)
 *
 * @example
 * // Basic usage
 * useChannel(socket, `chat:${roomId}`, {
 *   message_created: ({ message }) => {
 *     setMessages(msgs => [...msgs, message]);
 *   },
 *   user_typing: ({ user }) => {
 *     setTypingUsers(users => [...users, user]);
 *   }
 * });
 *
 * @example
 * // With type safety
 * interface ChatEvents {
 *   message_created: { message: Message };
 *   user_typing: { user: User };
 * }
 *
 * useChannel<ChatEvents>(socket, `chat:${roomId}`, {
 *   message_created: ({ message }) => {
 *     // message is typed as Message
 *   }
 * });
 *
 * @example
 * // With options
 * useChannel(socket, `game:${gameId}`, handlers, {
 *   params: { player_id: playerId },
 *   onJoin: (response) => console.log('Joined game:', response),
 *   onError: (error) => console.error('Join failed:', error),
 *   enabled: isLoggedIn,
 * });
 */
export declare function useChannel<TEvents extends Record<string, unknown> = Record<string, unknown>>(socket: Socket | null, topic: string, handlers: EventHandlers<TEvents>, options?: ChannelOptions): Channel | null;

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

/**
 * Return type for useChannelProps hook
 */
export declare interface UseChannelPropsReturn<T extends Record<string, unknown>> extends UseRealtimePropsReturn<T> {
}

/**
 * React hook for Phoenix Presence with automatic sync and diff tracking
 *
 * Provides real-time presence tracking for users in a channel with
 * automatic state synchronization.
 *
 * @template T - Type for presence meta data
 * @param socket - Phoenix Socket instance
 * @param topic - Channel topic (e.g., "room:123")
 * @param options - Presence options
 * @returns Object with presences state and helper methods
 *
 * @example
 * const { presences, list } = usePresence<UserMeta>(socket, `room:${roomId}`);
 *
 * // Get list of users
 * const users = list();
 * // => [{ id: "user:1", metas: [{ name: "Alice", online_at: "..." }] }]
 *
 * @example
 * // With callbacks
 * const { presences } = usePresence<UserMeta>(socket, `room:${roomId}`, {
 *   onSync: () => console.log('Presence synced'),
 *   onJoin: (id, current, newPres) => console.log(`${id} joined`),
 *   onLeave: (id, current, leftPres) => console.log(`${id} left`),
 * });
 */
export declare function usePresence<T = unknown>(socket: Socket | null, topic: string, options?: PresenceOptions): {
    presences: PresenceState<T>;
    list: () => Array<{
        id: string;
        metas: T[];
    }>;
    getByKey: (key: string) => T[] | undefined;
};

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
export declare function useRealtimeProps<T extends Record<string, unknown> = Record<string, unknown>>(): UseRealtimePropsReturn<T>;

/**
 * Return type for useRealtimeProps hook
 */
export declare interface UseRealtimePropsReturn<T extends Record<string, unknown>> {
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
