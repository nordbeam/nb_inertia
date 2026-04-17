declare module 'phoenix' {
  export interface Push {
    receive(
      status: 'ok' | 'error' | 'timeout',
      callback: (response: unknown) => void
    ): Push;
  }

  export class Channel {
    on(
      event: string,
      callback: (payload: unknown, ref?: string, joinRef?: string) => void
    ): string | number;
    onClose(callback: () => void): void;
    join(timeout?: number): Push;
    leave(timeout?: number): Push;
  }

  export class Socket {
    constructor(endpoint: string, opts?: Record<string, unknown>);
    connect(params?: Record<string, unknown>): void;
    disconnect(callback?: () => void, code?: number, reason?: string): void;
    channel(topic: string, params?: Record<string, unknown>): Channel;
    connectionState(): string;
  }

  export class Presence {
    constructor(channel: Channel);
    state: Record<string, { metas: unknown[] }>;
    onSync(callback: () => void): void;
    onJoin(callback: (id: string, current: unknown, newPres: unknown) => void): void;
    onLeave(callback: (id: string, current: unknown, leftPres: unknown) => void): void;
  }
}
