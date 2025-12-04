/**
 * Integration tests for useRealtimeProps hook
 *
 * Tests verify that the hook correctly manages optimistic state,
 * syncs with server props on navigation, and provides prop update methods.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useRealtimeProps } from '../useRealtimeProps';

// Mock Inertia usePage
let mockServerProps = { messages: [], room: { id: 1, name: 'Test Room' } };

vi.mock('@inertiajs/react', () => ({
  usePage: vi.fn(() => ({ props: mockServerProps })),
  router: {
    reload: vi.fn((options) => {
      // Simulate success callback
      options?.onSuccess?.();
    }),
  },
}));

describe('useRealtimeProps Hook', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockServerProps = { messages: [], room: { id: 1, name: 'Test Room' } };
  });

  describe('props access', () => {
    it('returns server props initially', () => {
      const { result } = renderHook(() => useRealtimeProps());

      expect(result.current.props).toEqual(mockServerProps);
    });

    it('merges optimistic updates with server props', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Hello' }]);
      });

      expect(result.current.props.messages).toEqual([{ id: 1, content: 'Hello' }]);
      expect(result.current.props.room).toEqual({ id: 1, name: 'Test Room' });
    });
  });

  describe('setProp', () => {
    it('updates prop with direct value', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Hello' }]);
      });

      expect(result.current.props.messages).toEqual([{ id: 1, content: 'Hello' }]);
    });

    it('updates prop with updater function', () => {
      mockServerProps = { messages: [{ id: 1, content: 'First' }], room: { id: 1, name: 'Test' } };

      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', (msgs: any[]) => [...msgs, { id: 2, content: 'Second' }]);
      });

      expect(result.current.props.messages).toEqual([
        { id: 1, content: 'First' },
        { id: 2, content: 'Second' },
      ]);
    });

    it('handles multiple sequential updates', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'First' }]);
      });

      act(() => {
        result.current.setProp('messages', (msgs: any[]) => [...msgs, { id: 2, content: 'Second' }]);
      });

      act(() => {
        result.current.setProp('messages', (msgs: any[]) => [...msgs, { id: 3, content: 'Third' }]);
      });

      expect(result.current.props.messages).toHaveLength(3);
    });

    it('uses latest server props in updater function', () => {
      const { result, rerender } = renderHook(() => useRealtimeProps());

      // Add optimistic update
      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Optimistic' }]);
      });

      // Simulate server update (would reset optimistic in real scenario)
      mockServerProps = { messages: [{ id: 1, content: 'From Server' }], room: { id: 1, name: 'Test' } };

      // Rerender to pick up new server props
      rerender();

      // After rerender, optimistic state should be reset
      expect(result.current.props.messages).toEqual([{ id: 1, content: 'From Server' }]);
    });
  });

  describe('setProps', () => {
    it('updates multiple props with object', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProps({
          messages: [{ id: 1, content: 'Hello' }],
          room: { id: 2, name: 'New Room' },
        });
      });

      expect(result.current.props.messages).toEqual([{ id: 1, content: 'Hello' }]);
      expect(result.current.props.room).toEqual({ id: 2, name: 'New Room' });
    });

    it('updates multiple props with updater function', () => {
      mockServerProps = { messages: [{ id: 1, content: 'First' }], room: { id: 1, name: 'Test' } };

      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProps((current) => ({
          messages: [...(current.messages as any[]), { id: 2, content: 'Second' }],
          room: { ...current.room, name: 'Updated Room' },
        }));
      });

      expect(result.current.props.messages).toEqual([
        { id: 1, content: 'First' },
        { id: 2, content: 'Second' },
      ]);
      expect(result.current.props.room.name).toBe('Updated Room');
    });
  });

  describe('hasOptimisticUpdates', () => {
    it('is false initially', () => {
      const { result } = renderHook(() => useRealtimeProps());

      expect(result.current.hasOptimisticUpdates).toBe(false);
    });

    it('is true after setProp', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Hello' }]);
      });

      expect(result.current.hasOptimisticUpdates).toBe(true);
    });

    it('is true after setProps', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProps({ messages: [] });
      });

      expect(result.current.hasOptimisticUpdates).toBe(true);
    });
  });

  describe('resetOptimistic', () => {
    it('clears optimistic updates', () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Hello' }]);
      });

      expect(result.current.hasOptimisticUpdates).toBe(true);

      act(() => {
        result.current.resetOptimistic();
      });

      expect(result.current.hasOptimisticUpdates).toBe(false);
      expect(result.current.props).toEqual(mockServerProps);
    });
  });

  describe('reload', () => {
    it('calls router.reload', async () => {
      const { router } = await import('@inertiajs/react');
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.reload();
      });

      expect(router.reload).toHaveBeenCalled();
    });

    it('passes only option to router.reload', async () => {
      const { router } = await import('@inertiajs/react');
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.reload({ only: ['messages'] });
      });

      expect(router.reload).toHaveBeenCalledWith(
        expect.objectContaining({
          only: ['messages'],
        })
      );
    });

    it('resets optimistic state on success', async () => {
      const { result } = renderHook(() => useRealtimeProps());

      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Optimistic' }]);
      });

      expect(result.current.hasOptimisticUpdates).toBe(true);

      act(() => {
        result.current.reload();
      });

      expect(result.current.hasOptimisticUpdates).toBe(false);
    });
  });

  describe('server props sync', () => {
    it('resets optimistic state when server props change', () => {
      const { result, rerender } = renderHook(() => useRealtimeProps());

      // Add optimistic update
      act(() => {
        result.current.setProp('messages', [{ id: 1, content: 'Optimistic' }]);
      });

      expect(result.current.hasOptimisticUpdates).toBe(true);

      // Simulate navigation/reload that updates server props
      mockServerProps = { messages: [{ id: 2, content: 'New from server' }], room: { id: 1, name: 'Test' } };
      rerender();

      // Optimistic state should be reset
      expect(result.current.hasOptimisticUpdates).toBe(false);
      expect(result.current.props.messages).toEqual([{ id: 2, content: 'New from server' }]);
    });
  });

  describe('type safety', () => {
    interface TestProps {
      messages: { id: number; content: string }[];
      room: { id: number; name: string };
      count?: number;
    }

    it('provides typed props access', () => {
      const { result } = renderHook(() => useRealtimeProps<TestProps>());

      // TypeScript would catch type errors here
      expect(result.current.props.messages).toEqual([]);
      expect(result.current.props.room.id).toBe(1);
    });

    it('provides typed setProp', () => {
      const { result } = renderHook(() => useRealtimeProps<TestProps>());

      act(() => {
        // This should be type-safe
        result.current.setProp('messages', [{ id: 1, content: 'Hello' }]);
        result.current.setProp('count', 5);
      });

      expect(result.current.props.messages).toEqual([{ id: 1, content: 'Hello' }]);
      expect(result.current.props.count).toBe(5);
    });
  });

  describe('real-world patterns', () => {
    it('handles chat message append pattern', () => {
      mockServerProps = { messages: [{ id: 1, content: 'First' }], room: { id: 1, name: 'Test' } };

      const { result } = renderHook(() => useRealtimeProps());

      // Simulate receiving multiple messages via WebSocket
      act(() => {
        result.current.setProp('messages', (msgs: any[]) => [...msgs, { id: 2, content: 'Second' }]);
      });

      act(() => {
        result.current.setProp('messages', (msgs: any[]) => [...msgs, { id: 3, content: 'Third' }]);
      });

      expect(result.current.props.messages).toHaveLength(3);
      expect(result.current.props.messages).toEqual([
        { id: 1, content: 'First' },
        { id: 2, content: 'Second' },
        { id: 3, content: 'Third' },
      ]);
    });

    it('handles notification badge pattern', () => {
      mockServerProps = { unreadCount: 0, notifications: [] };

      const { result } = renderHook(() => useRealtimeProps());

      // Simulate new notification
      act(() => {
        result.current.setProps((current) => ({
          unreadCount: (current.unreadCount as number) + 1,
          notifications: [...(current.notifications as any[]), { id: 1, text: 'New message' }],
        }));
      });

      expect(result.current.props.unreadCount).toBe(1);
      expect((result.current.props.notifications as any[]).length).toBe(1);
    });

    it('handles typing indicator pattern', () => {
      mockServerProps = { typingUsers: [], messages: [] };

      const { result } = renderHook(() => useRealtimeProps());

      // User starts typing
      act(() => {
        result.current.setProp('typingUsers', [{ id: 1, name: 'Alice' }]);
      });

      expect(result.current.props.typingUsers).toEqual([{ id: 1, name: 'Alice' }]);

      // Another user starts typing
      act(() => {
        result.current.setProp('typingUsers', (users: any[]) => [...users, { id: 2, name: 'Bob' }]);
      });

      expect(result.current.props.typingUsers).toHaveLength(2);

      // Users stop typing
      act(() => {
        result.current.setProp('typingUsers', []);
      });

      expect(result.current.props.typingUsers).toEqual([]);
    });

    it('handles item removal pattern', () => {
      mockServerProps = {
        messages: [
          { id: 1, content: 'First' },
          { id: 2, content: 'Second' },
          { id: 3, content: 'Third' },
        ],
        room: { id: 1, name: 'Test' },
      };

      const { result } = renderHook(() => useRealtimeProps());

      // Delete message with id 2
      act(() => {
        result.current.setProp('messages', (msgs: any[]) => msgs.filter((m) => m.id !== 2));
      });

      expect(result.current.props.messages).toEqual([
        { id: 1, content: 'First' },
        { id: 3, content: 'Third' },
      ]);
    });

    it('handles item update pattern', () => {
      mockServerProps = {
        messages: [
          { id: 1, content: 'Original' },
          { id: 2, content: 'Keep this' },
        ],
        room: { id: 1, name: 'Test' },
      };

      const { result } = renderHook(() => useRealtimeProps());

      // Update message with id 1
      act(() => {
        result.current.setProp('messages', (msgs: any[]) =>
          msgs.map((m) => (m.id === 1 ? { ...m, content: 'Edited' } : m))
        );
      });

      expect(result.current.props.messages).toEqual([
        { id: 1, content: 'Edited' },
        { id: 2, content: 'Keep this' },
      ]);
    });
  });
});
