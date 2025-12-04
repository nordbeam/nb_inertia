/**
 * NbInertia Realtime Module for React
 *
 * Provides Phoenix Channel integration and real-time prop updates for Inertia.js.
 *
 * ## Quick Start
 *
 * ```typescript
 * import { createSocket, useChannel, useRealtimeProps } from '@/lib/realtime';
 *
 * // 1. Create socket (once, in app setup)
 * export const socket = createSocket('/socket');
 *
 * // 2. Use in components
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
 * ```
 *
 * ## Declarative Mode
 *
 * ```typescript
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
 * ```
 *
 * @module
 */
export { createSocket, useChannel, usePresence, Socket, Channel, Presence, type EventHandler, type EventHandlers, type ChannelOptions, type PresenceState, type PresenceOptions, type SocketOptions, } from './socket';
export { useRealtimeProps, type ReloadOptions, type UseRealtimePropsReturn, } from './useRealtimeProps';
export { useChannelProps, type UpdateStrategy, type AppendStrategy, type PrependStrategy, type RemoveStrategy, type UpdateStrategy_ as UpdateItemStrategy, type UpsertStrategy, type ReplaceStrategy, type ReloadStrategy, type DeclarativeEventConfig, type CustomEventHandler, type EventConfig, type EventConfigs, type UseChannelPropsReturn, } from './useChannelProps';
//# sourceMappingURL=index.d.ts.map