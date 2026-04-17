import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useForm, useFormWithPrecognition } from '../useForm';
import type { RouteResult } from '../../shared/types';

const mockUseForm = vi.fn();
const mockSubmit = vi.fn();

vi.mock('@inertiajs/react', () => ({
  useForm: (...args: unknown[]) => mockUseForm(...args),
}));

describe('useForm (React)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUseForm.mockReturnValue({
      submit: mockSubmit,
      data: { title: 'Test Post' },
      setData: vi.fn(),
      errors: {},
      processing: false,
    });
  });

  it('passes route-first arguments through to native useForm', () => {
    const route: RouteResult = { url: '/posts', method: 'post' };

    renderHook(() => useForm(route, { title: 'Test Post' }));

    expect(mockUseForm).toHaveBeenCalledWith(route, { title: 'Test Post' });
  });

  it('swaps legacy data-first route binding arguments', () => {
    const route: RouteResult = { url: '/posts/1', method: 'patch' };

    renderHook(() => useForm({ title: 'Updated' }, route));

    expect(mockUseForm).toHaveBeenCalledWith(route, { title: 'Updated' });
  });

  it('preserves remember-key overloads', () => {
    renderHook(() => useForm('posts-form', { title: 'Remembered' }));

    expect(mockUseForm).toHaveBeenCalledWith('posts-form', { title: 'Remembered' });
  });

  it('preserves explicit method/url precognition overloads', () => {
    renderHook(() => useForm('post', '/posts', { title: 'Created' }));

    expect(mockUseForm).toHaveBeenCalledWith('post', '/posts', { title: 'Created' });
  });

  it('supports lazy route resolvers', () => {
    const route = () => ({ url: '/posts/1', method: 'patch' as const });
    const data = () => ({ title: 'Lazy' });

    renderHook(() => useForm(route, data));

    expect(mockUseForm).toHaveBeenCalledWith(route, data);
  });

  it('rewrites submit for separate submission routes', () => {
    const validateRoute: RouteResult = { url: '/posts/validate', method: 'post' };
    const submitRoute: RouteResult = { url: '/posts', method: 'post' };

    const { result } = renderHook(() =>
      useFormWithPrecognition({ title: 'Test Post' }, validateRoute, submitRoute)
    );

    act(() => {
      result.current.submit({ preserveScroll: true });
    });

    expect(mockUseForm).toHaveBeenCalledWith(validateRoute, { title: 'Test Post' });
    expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', { preserveScroll: true });
  });
});
