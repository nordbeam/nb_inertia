/**
 * NbInertia Phoenix Socket Integration for React
 *
 * Provides React hooks for Phoenix Channels with automatic lifecycle management,
 * type safety, and seamless integration with Inertia.js.
 *
 * @example
 * // Setup in your app
 * import { createSocket, useChannel } from '@/lib/socket';
 *
 * // Create and connect socket
 * export const socket = createSocket('/socket');
 *
 * // Use in components
 * function ChatRoom({ room }) {
 *   useChannel(`chat:${room.id}`, {
 *     message_created: ({ message }) => {
 *       // Handle new message
 *     }
 *   });
 * }
 */

import { useEffect, useRef, useState, useCallback } from 'react';
import { Socket, Channel, Presence } from 'phoenix';

// ============================================================================
// Types
// ============================================================================

/**
 * Event handler function type
 */
export type EventHandler<T = unknown> = (payload: T) => void;

/**
 * Map of event names to their handlers
 */
export type EventHandlers<T extends Record<string, unknown> = Record<string, unknown>> = {
  [K in keyof T]?: EventHandler<T[K]>;
};

/**
 * Options for useChannel hook
 */
export interface ChannelOptions {
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
 * Presence state structure from Phoenix Presence
 */
export interface PresenceState<T = unknown> {
  [key: string]: { metas: T[] };
}

/**
 * Options for usePresence hook
 */
export interface PresenceOptions extends ChannelOptions {
  /** Callback when presence syncs */
  onSync?: () => void;
  /** Callback when a user joins */
  onJoin?: (id: string, current: unknown, newPres: unknown) => void;
  /** Callback when a user leaves */
  onLeave?: (id: string, current: unknown, leftPres: unknown) => void;
}

/**
 * Socket configuration options
 */
export interface SocketOptions {
  /** Parameters to send with the socket connection */
  params?: (() => Record<string, unknown>) | Record<string, unknown>;
  /** Logger function for debugging */
  logger?: (kind: string, msg: string, data: unknown) => void;
  /** Reconnect after error delay in ms (default: 10000) */
  reconnectAfterMs?: (tries: number) => number;
  /** Heartbeat interval in ms (default: 30000) */
  heartbeatIntervalMs?: number;
}

// ============================================================================
// Socket Factory
// ============================================================================

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
export function createSocket(endpoint: string, options: SocketOptions = {}): Socket {
  const socket = new Socket(endpoint, {
    params: options.params ?? (() => {
      const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
      return { _csrf_token: token?.content };
    }),
    logger: options.logger ?? ((kind, msg, data) => {
      if (import.meta.env?.DEV) {
        console.debug(`[socket:${kind}]`, msg, data);
      }
    }),
    reconnectAfterMs: options.reconnectAfterMs,
    heartbeatIntervalMs: options.heartbeatIntervalMs,
  });

  return socket;
}

// ============================================================================
// useChannel Hook
// ============================================================================

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
export function useChannel<TEvents extends Record<string, unknown> = Record<string, unknown>>(
  socket: Socket | null,
  topic: string,
  handlers: EventHandlers<TEvents>,
  options: ChannelOptions = {}
): Channel | null {
  const channelRef = useRef<Channel | null>(null);
  const handlersRef = useRef(handlers);
  const { enabled = true } = options;

  // Keep handlers up to date without triggering rejoin
  handlersRef.current = handlers;

  useEffect(() => {
    // Don't connect if socket is null, disabled, or no topic
    if (!socket || !enabled || !topic) {
      return;
    }

    // Ensure socket is connected
    if (socket.connectionState() !== 'open') {
      socket.connect();
    }

    const channel = socket.channel(topic, options.params);
    channelRef.current = channel;

    // Register event handlers using stable wrappers that delegate to ref
    const events = Object.keys(handlers) as (keyof TEvents)[];
    events.forEach((event) => {
      channel.on(event as string, (payload) => {
        handlersRef.current[event]?.(payload as TEvents[typeof event]);
      });
    });

    // Join the channel
    channel
      .join()
      .receive('ok', (response) => {
        if (import.meta.env?.DEV) {
          console.debug(`[channel] Joined ${topic}`);
        }
        options.onJoin?.(response);
      })
      .receive('error', (error) => {
        console.error(`[channel] Failed to join ${topic}:`, error);
        options.onError?.(error);
      });

    // Handle channel close
    channel.onClose(() => {
      if (import.meta.env?.DEV) {
        console.debug(`[channel] Left ${topic}`);
      }
      options.onClose?.();
    });

    // Cleanup: leave channel on unmount
    return () => {
      channel.leave();
      channelRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [socket, topic, enabled, JSON.stringify(options.params)]);
  // Note: handlers intentionally excluded from deps - we use ref to avoid rejoins

  return channelRef.current;
}

// ============================================================================
// usePresence Hook
// ============================================================================

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
export function usePresence<T = unknown>(
  socket: Socket | null,
  topic: string,
  options: PresenceOptions = {}
): {
  presences: PresenceState<T>;
  list: () => Array<{ id: string; metas: T[] }>;
  getByKey: (key: string) => T[] | undefined;
} {
  const [presences, setPresences] = useState<PresenceState<T>>({});
  const { enabled = true } = options;

  useEffect(() => {
    if (!socket || !enabled || !topic) {
      return;
    }

    // Ensure socket is connected
    if (socket.connectionState() !== 'open') {
      socket.connect();
    }

    const channel = socket.channel(topic, options.params);
    const presence = new Presence(channel);

    // Set up presence callbacks
    presence.onSync(() => {
      setPresences({ ...presence.state } as PresenceState<T>);
      options.onSync?.();
    });

    if (options.onJoin) {
      presence.onJoin(options.onJoin);
    }

    if (options.onLeave) {
      presence.onLeave(options.onLeave);
    }

    // Join the channel
    channel
      .join()
      .receive('ok', (response) => {
        if (import.meta.env?.DEV) {
          console.debug(`[presence] Joined ${topic}`);
        }
      })
      .receive('error', (error) => {
        console.error(`[presence] Failed to join ${topic}:`, error);
        options.onError?.(error);
      });

    return () => {
      channel.leave();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [socket, topic, enabled, JSON.stringify(options.params)]);

  const list = useCallback(() => {
    return Object.entries(presences).map(([id, { metas }]) => ({ id, metas }));
  }, [presences]);

  const getByKey = useCallback(
    (key: string) => {
      return presences[key]?.metas;
    },
    [presences]
  );

  return { presences, list, getByKey };
}

// ============================================================================
// Exports
// ============================================================================

export { Socket, Channel, Presence };
