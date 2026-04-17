import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useForm, useFormWithPrecognition } from '../useForm';
import type { RouteResult } from '../../shared/types';

const mockUseForm = vi.fn();
const mockSubmit = vi.fn();

vi.mock('@inertiajs/vue3', () => ({
  useForm: (...args: unknown[]) => mockUseForm(...args),
}));

describe('useForm (Vue)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUseForm.mockReturnValue({
      submit: mockSubmit,
      data: vi.fn(() => ({ title: 'Test Post' })),
      defaults: vi.fn(),
      errors: {},
      processing: false,
    });
  });

  it('passes route-first arguments through to native useForm', () => {
    const route: RouteResult = { url: '/posts', method: 'post' };

    useForm(route, { title: 'Test Post' });

    expect(mockUseForm).toHaveBeenCalledWith(route, { title: 'Test Post' });
  });

  it('swaps legacy data-first route binding arguments', () => {
    const route: RouteResult = { url: '/posts/1', method: 'patch' };

    useForm({ title: 'Updated' }, route);

    expect(mockUseForm).toHaveBeenCalledWith(route, { title: 'Updated' });
  });

  it('preserves remember-key overloads', () => {
    useForm('posts-form', { title: 'Remembered' });

    expect(mockUseForm).toHaveBeenCalledWith('posts-form', { title: 'Remembered' });
  });

  it('preserves explicit method/url precognition overloads', () => {
    useForm('post', '/posts', { title: 'Created' });

    expect(mockUseForm).toHaveBeenCalledWith('post', '/posts', { title: 'Created' });
  });

  it('supports lazy route resolvers', () => {
    const route = () => ({ url: '/posts/1', method: 'patch' as const });
    const data = () => ({ title: 'Lazy' });

    useForm(route, data);

    expect(mockUseForm).toHaveBeenCalledWith(route, data);
  });

  it('rewrites submit for separate submission routes', () => {
    const validateRoute: RouteResult = { url: '/posts/validate', method: 'post' };
    const submitRoute: RouteResult = { url: '/posts', method: 'post' };
    const form = useFormWithPrecognition({ title: 'Test Post' }, validateRoute, submitRoute);

    form.submit({ preserveScroll: true });

    expect(mockUseForm).toHaveBeenCalledWith(validateRoute, { title: 'Test Post' });
    expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', { preserveScroll: true });
  });
});
