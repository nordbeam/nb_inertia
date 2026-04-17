import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useHttp, useHttpWithPrecognition } from '../useHttp';
import type { RouteResult } from '../../shared/types';

const mockUseHttp = vi.fn();
const mockSubmit = vi.fn();

vi.mock('@inertiajs/react', () => ({
  useHttp: (...args: unknown[]) => mockUseHttp(...args),
}));

describe('useHttp (React)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUseHttp.mockReturnValue({
      submit: mockSubmit,
      data: { title: 'Test Post' },
      setData: vi.fn(),
      errors: {},
      processing: false,
      response: null,
    });
  });

  it('passes route-first arguments through to native useHttp', () => {
    const route: RouteResult = { url: '/posts', method: 'post' };

    renderHook(() => useHttp(route, { title: 'Test Post' }));

    expect(mockUseHttp).toHaveBeenCalledWith(route, { title: 'Test Post' });
  });

  it('swaps legacy data-first route binding arguments', () => {
    const route: RouteResult = { url: '/posts/1', method: 'patch' };

    renderHook(() => useHttp({ title: 'Updated' }, route));

    expect(mockUseHttp).toHaveBeenCalledWith(route, { title: 'Updated' });
  });

  it('preserves remember-key overloads', () => {
    renderHook(() => useHttp('posts-http', { title: 'Remembered' }));

    expect(mockUseHttp).toHaveBeenCalledWith('posts-http', { title: 'Remembered' });
  });

  it('preserves explicit method/url overloads', () => {
    renderHook(() => useHttp('post', '/posts', { title: 'Created' }));

    expect(mockUseHttp).toHaveBeenCalledWith('post', '/posts', { title: 'Created' });
  });

  it('supports lazy route resolvers', () => {
    const route = () => ({ url: '/posts/1', method: 'patch' as const });
    const data = () => ({ title: 'Lazy' });

    renderHook(() => useHttp(route, data));

    expect(mockUseHttp).toHaveBeenCalledWith(route, data);
  });

  it('rewrites submit for separate submission routes', async () => {
    const validateRoute: RouteResult = { url: '/posts/validate', method: 'post' };
    const submitRoute: RouteResult = { url: '/posts', method: 'post' };
    mockSubmit.mockResolvedValue({ ok: true });

    const { result } = renderHook(() =>
      useHttpWithPrecognition({ title: 'Test Post' }, validateRoute, submitRoute)
    );

    await act(async () => {
      await result.current.submit({ preserveScroll: true });
    });

    expect(mockUseHttp).toHaveBeenCalledWith(validateRoute, { title: 'Test Post' });
    expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', { preserveScroll: true });
  });
});
