import { Channel } from 'phoenix';
import { Presence } from 'phoenix';
import { Socket } from 'phoenix';

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
 * Event handler function type
 */
export declare type EventHandler<T = unknown> = (payload: T) => void;

/**
 * Map of event names to their handlers
 */
export declare type EventHandlers<T extends Record<string, unknown> = Record<string, unknown>> = {
    [K in keyof T]?: EventHandler<T[K]>;
};

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

export { }
