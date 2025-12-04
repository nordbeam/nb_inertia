/**
 * Integration tests for useChannel hook
 *
 * Tests verify that the hook correctly subscribes to Phoenix Channels,
 * handles events, and manages the channel lifecycle.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useChannel, createSocket } from '../socket';
import type { Socket, Channel } from 'phoenix';

// Mock Phoenix Channel
const mockOn = vi.fn();
const mockJoin = vi.fn(() => ({
  receive: vi.fn((event, callback) => {
    if (event === 'ok') {
      callback({});
    }
    return { receive: vi.fn().mockReturnThis() };
  }),
}));
const mockLeave = vi.fn();
const mockOnClose = vi.fn();

const mockChannel = {
  on: mockOn,
  join: mockJoin,
  leave: mockLeave,
  onClose: mockOnClose,
} as unknown as Channel;

// Mock Phoenix Socket
const mockSocketChannel = vi.fn(() => mockChannel);
const mockConnect = vi.fn();
const mockConnectionState = vi.fn(() => 'open');

const mockSocket = {
  channel: mockSocketChannel,
  connect: mockConnect,
  connectionState: mockConnectionState,
} as unknown as Socket;

describe('useChannel Hook', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockConnectionState.mockReturnValue('open');
  });

  describe('channel subscription', () => {
    it('creates channel with topic', () => {
      renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: vi.fn(),
        })
      );

      expect(mockSocketChannel).toHaveBeenCalledWith('room:123', undefined);
    });

    it('creates channel with params', () => {
      renderHook(() =>
        useChannel(
          mockSocket,
          'room:123',
          { message_created: vi.fn() },
          { params: { user_id: 1 } }
        )
      );

      expect(mockSocketChannel).toHaveBeenCalledWith('room:123', { user_id: 1 });
    });

    it('registers event handlers', () => {
      const handler1 = vi.fn();
      const handler2 = vi.fn();

      renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: handler1,
          user_joined: handler2,
        })
      );

      expect(mockOn).toHaveBeenCalledWith('message_created', expect.any(Function));
      expect(mockOn).toHaveBeenCalledWith('user_joined', expect.any(Function));
    });

    it('joins the channel', () => {
      renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: vi.fn(),
        })
      );

      expect(mockJoin).toHaveBeenCalled();
    });
  });

  describe('socket connection', () => {
    it('connects socket if not already connected', () => {
      mockConnectionState.mockReturnValue('closed');

      renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: vi.fn(),
        })
      );

      expect(mockConnect).toHaveBeenCalled();
    });

    it('does not connect if already connected', () => {
      mockConnectionState.mockReturnValue('open');

      renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: vi.fn(),
        })
      );

      expect(mockConnect).not.toHaveBeenCalled();
    });
  });

  describe('cleanup', () => {
    it('leaves channel on unmount', () => {
      const { unmount } = renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: vi.fn(),
        })
      );

      unmount();

      expect(mockLeave).toHaveBeenCalled();
    });
  });

  describe('topic changes', () => {
    it('rejoins channel when topic changes', () => {
      let topic = 'room:123';

      const { rerender } = renderHook(() =>
        useChannel(mockSocket, topic, {
          message_created: vi.fn(),
        })
      );

      expect(mockSocketChannel).toHaveBeenCalledWith('room:123', undefined);
      expect(mockJoin).toHaveBeenCalledTimes(1);

      // Change topic
      topic = 'room:456';
      rerender();

      expect(mockLeave).toHaveBeenCalled();
      expect(mockSocketChannel).toHaveBeenCalledWith('room:456', undefined);
    });
  });

  describe('enabled option', () => {
    it('does not subscribe when disabled', () => {
      renderHook(() =>
        useChannel(
          mockSocket,
          'room:123',
          { message_created: vi.fn() },
          { enabled: false }
        )
      );

      expect(mockSocketChannel).not.toHaveBeenCalled();
    });

    it('subscribes when enabled changes to true', () => {
      let enabled = false;

      const { rerender } = renderHook(() =>
        useChannel(
          mockSocket,
          'room:123',
          { message_created: vi.fn() },
          { enabled }
        )
      );

      expect(mockSocketChannel).not.toHaveBeenCalled();

      enabled = true;
      rerender();

      expect(mockSocketChannel).toHaveBeenCalled();
    });
  });

  describe('null socket', () => {
    it('does not subscribe when socket is null', () => {
      renderHook(() =>
        useChannel(null, 'room:123', {
          message_created: vi.fn(),
        })
      );

      expect(mockSocketChannel).not.toHaveBeenCalled();
    });
  });

  describe('callbacks', () => {
    it('calls onJoin on successful join', () => {
      const onJoin = vi.fn();

      renderHook(() =>
        useChannel(
          mockSocket,
          'room:123',
          { message_created: vi.fn() },
          { onJoin }
        )
      );

      expect(onJoin).toHaveBeenCalledWith({});
    });

    it('sets up onClose callback', () => {
      const onClose = vi.fn();

      renderHook(() =>
        useChannel(
          mockSocket,
          'room:123',
          { message_created: vi.fn() },
          { onClose }
        )
      );

      expect(mockOnClose).toHaveBeenCalled();
    });
  });

  describe('handler updates', () => {
    it('uses latest handler without rejoining', () => {
      let handler = vi.fn();
      let capturedHandler: ((payload: any) => void) | null = null;

      // Capture the wrapped handler
      mockOn.mockImplementation((event, wrappedHandler) => {
        if (event === 'message_created') {
          capturedHandler = wrappedHandler;
        }
      });

      const { rerender } = renderHook(() =>
        useChannel(mockSocket, 'room:123', {
          message_created: handler,
        })
      );

      // Initial join
      expect(mockJoin).toHaveBeenCalledTimes(1);

      // Update handler
      const newHandler = vi.fn();
      handler = newHandler;
      rerender();

      // Should not rejoin
      expect(mockJoin).toHaveBeenCalledTimes(1);

      // Simulate event - should call new handler
      if (capturedHandler) {
        capturedHandler({ content: 'test' });
      }

      expect(newHandler).toHaveBeenCalledWith({ content: 'test' });
    });
  });
});

describe('createSocket', () => {
  it('creates socket with default params', () => {
    // This would require mocking the Phoenix Socket constructor
    // For now, we just verify the function exists and is callable
    expect(createSocket).toBeDefined();
    expect(typeof createSocket).toBe('function');
  });
});
