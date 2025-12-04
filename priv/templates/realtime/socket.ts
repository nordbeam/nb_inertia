/**
 * Phoenix Socket Configuration
 *
 * This file sets up the Phoenix Socket connection and re-exports
 * channel hooks from @nordbeam/nb-inertia for real-time features.
 *
 * Usage:
 *   import { socket, useChannel, useRealtimeProps } from '@/lib/socket';
 *
 *   function ChatRoom({ room }) {
 *     const { props, setProp } = useRealtimeProps<ChatRoomProps>();
 *
 *     useChannel(socket, `chat:${room.id}`, {
 *       message_created: ({ message }) => {
 *         setProp('messages', msgs => [...msgs, message]);
 *       }
 *     });
 *
 *     return <div>{props.messages.map(m => <Message key={m.id} {...m} />)}</div>;
 *   }
 */

import {
  createSocket,
  useChannel,
  usePresence,
  useRealtimeProps,
  useChannelProps,
} from '@nordbeam/nb-inertia/react/realtime';

// Create and connect the socket
export const socket = createSocket('/socket', {
  params: () => {
    const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
    return { _csrf_token: token?.content };
  },
});

// Connect the socket
socket.connect();

// Re-export hooks for convenience
export {
  useChannel,
  usePresence,
  useRealtimeProps,
  useChannelProps,
  createSocket,
};

// Re-export types
export type {
  EventHandler,
  EventHandlers,
  ChannelOptions,
  PresenceState,
  PresenceOptions,
  SocketOptions,
  ReloadOptions,
  UseRealtimePropsReturn,
  UpdateStrategy,
  DeclarativeEventConfig,
  CustomEventHandler,
  EventConfig,
  EventConfigs,
  UseChannelPropsReturn,
} from '@nordbeam/nb-inertia/react/realtime';
