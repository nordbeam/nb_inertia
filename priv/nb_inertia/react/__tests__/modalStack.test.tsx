import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { ModalStackProvider, useModalStack } from '../modals';

const mockVisit = vi.fn();
const mockOn = vi.fn(() => () => {});

vi.mock('@inertiajs/react', () => ({
  router: {
    visit: (...args: unknown[]) => mockVisit(...args),
    on: (...args: unknown[]) => mockOn(...args),
  },
}));

describe('ModalStackProvider (React)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    window.history.replaceState({}, '', '/users?page=2');
  });

  it('opens loading modals through visitModal and sends modal headers', () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider>{children}</ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.visitModal('/users/1/edit');
    });

    expect(result.current.modals).toHaveLength(1);
    expect(result.current.modals[0]?.loading).toBe(true);
    expect(result.current.modals[0]?.returnUrl).toBe('http://localhost:3000/users?page=2');
    expect(mockVisit).toHaveBeenCalledWith(
      '/users/1/edit',
      expect.objectContaining({
        method: 'get',
        preserveState: true,
        preserveScroll: true,
        headers: {
          'x-inertia-modal': 'true',
          'x-inertia-modal-base-url': 'http://localhost:3000/users?page=2',
        },
      })
    );
  });
});
