/**
 * Integration tests for enhanced NbInertia useForm hook
 *
 * Tests verify that the useForm hook correctly handles optional route binding,
 * provides simplified submit() when bound, and maintains backward compatibility
 * with standard Inertia useForm when not bound.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useForm } from '../useForm';
import type { RouteResult } from '../router';

// Mock Inertia useForm
const mockSubmit = vi.fn();
const mockSetData = vi.fn();
const mockTransform = vi.fn();
const mockReset = vi.fn();
const mockClearErrors = vi.fn();

vi.mock('@inertiajs/react', () => ({
  useForm: vi.fn((initialData) => ({
    data: initialData,
    setData: mockSetData,
    transform: mockTransform,
    reset: mockReset,
    clearErrors: mockClearErrors,
    submit: mockSubmit,
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    cancel: vi.fn(),
    errors: {},
    hasErrors: false,
    processing: false,
    progress: null,
    wasSuccessful: false,
    recentlySuccessful: false,
    isDirty: false,
  })),
}));

describe('useForm Hook', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('when bound to a route', () => {
    it('returns form with enhanced submit method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.submit).toBeDefined();
    });

    it('submit() uses route URL and method without arguments', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', undefined);
    });

    it('submit() accepts visit options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      act(() => {
        result.current.submit({
          preserveScroll: true,
          preserveState: true,
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        preserveScroll: true,
        preserveState: true,
      });
    });

    it('works with GET method', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'get',
      };

      const { result } = renderHook(() =>
        useForm({ search: 'test' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('get', '/posts', undefined);
    });

    it('works with POST method', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'New Post' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', undefined);
    });

    it('works with PUT method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Replaced Post' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('put', '/posts/1', undefined);
    });

    it('works with PATCH method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Updated Post' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', undefined);
    });

    it('works with DELETE method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const { result } = renderHook(() => useForm({}, route));

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith('delete', '/posts/1', undefined);
    });

    it('preserves all other form properties', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.data).toEqual({ title: 'Test Post' });
      expect(result.current.setData).toBeDefined();
      expect(result.current.transform).toBeDefined();
      expect(result.current.reset).toBeDefined();
      expect(result.current.clearErrors).toBeDefined();
      expect(result.current.errors).toBeDefined();
      expect(result.current.processing).toBeDefined();
      expect(result.current.wasSuccessful).toBeDefined();
      expect(result.current.recentlySuccessful).toBeDefined();
      expect(result.current.isDirty).toBeDefined();
    });

    it('submit() passes through onSuccess callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const onSuccess = vi.fn();

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      act(() => {
        result.current.submit({ onSuccess });
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        onSuccess,
      });
    });

    it('submit() passes through onError callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const onError = vi.fn();

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      act(() => {
        result.current.submit({ onError });
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        onError,
      });
    });

    it('submit() passes through all visit options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      const options = {
        preserveScroll: true,
        preserveState: true,
        only: ['post'],
        headers: { 'X-Custom': 'value' },
        errorBag: 'post',
        forceFormData: false,
        onBefore: vi.fn(),
        onStart: vi.fn(),
        onProgress: vi.fn(),
        onSuccess: vi.fn(),
        onError: vi.fn(),
        onCancel: vi.fn(),
        onFinish: vi.fn(),
      };

      act(() => {
        result.current.submit(options);
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', options);
    });
  });

  describe('when not bound to a route', () => {
    it('returns standard Inertia form', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' })
      );

      expect(result.current.submit).toBe(mockSubmit);
    });

    it('submit() requires method and URL parameters', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' })
      );

      act(() => {
        // Standard Inertia useForm signature
        result.current.submit('patch', '/posts/1');
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1');
    });

    it('submit() accepts options as third parameter', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' })
      );

      act(() => {
        result.current.submit('patch', '/posts/1', {
          preserveScroll: true,
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        preserveScroll: true,
      });
    });

    it('preserves all standard useForm properties', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' })
      );

      expect(result.current.data).toEqual({ title: 'Test Post' });
      expect(result.current.setData).toBeDefined();
      expect(result.current.transform).toBeDefined();
      expect(result.current.reset).toBeDefined();
      expect(result.current.clearErrors).toBeDefined();
      expect(result.current.errors).toBeDefined();
      expect(result.current.processing).toBeDefined();
      expect(result.current.wasSuccessful).toBeDefined();
      expect(result.current.recentlySuccessful).toBeDefined();
      expect(result.current.isDirty).toBeDefined();
    });
  });

  describe('form data management', () => {
    it('initializes with provided data', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const initialData = {
        title: 'Test Post',
        content: 'Test content',
        published: true,
      };

      const { result } = renderHook(() => useForm(initialData, route));

      expect(result.current.data).toEqual(initialData);
    });

    it('setData is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.setData).toBe(mockSetData);
    });

    it('transform is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.transform).toBe(mockTransform);
    });

    it('reset is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.reset).toBe(mockReset);
    });

    it('clearErrors is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test Post' }, route)
      );

      expect(result.current.clearErrors).toBe(mockClearErrors);
    });
  });

  describe('edge cases', () => {
    it('handles empty data object', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const { result } = renderHook(() => useForm({}, route));

      expect(result.current.data).toEqual({});
    });

    it('handles complex nested data', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const complexData = {
        title: 'Test Post',
        metadata: {
          author: 'John Doe',
          tags: ['tag1', 'tag2'],
          settings: {
            published: true,
            featured: false,
          },
        },
      };

      const { result } = renderHook(() => useForm(complexData, route));

      expect(result.current.data).toEqual(complexData);
    });

    it('handles URLs with query parameters', () => {
      const route: RouteResult = {
        url: '/posts?category=tech&page=2',
        method: 'get',
      };

      const { result } = renderHook(() =>
        useForm({ search: 'test' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith(
        'get',
        '/posts?category=tech&page=2',
        undefined
      );
    });

    it('handles URLs with hash fragments', () => {
      const route: RouteResult = {
        url: '/posts/1#comments',
        method: 'get',
      };

      const { result } = renderHook(() => useForm({}, route));

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith(
        'get',
        '/posts/1#comments',
        undefined
      );
    });

    it('handles absolute URLs', () => {
      const route: RouteResult = {
        url: 'https://example.com/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      act(() => {
        result.current.submit();
      });

      expect(mockSubmit).toHaveBeenCalledWith(
        'patch',
        'https://example.com/posts/1',
        undefined
      );
    });
  });

  describe('type guard validation', () => {
    it('treats invalid RouteResult as unbound form', () => {
      const invalidRoute = { url: '/posts/1' } as any;

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, invalidRoute)
      );

      // Should return standard Inertia form (unbound)
      expect(result.current.submit).toBe(mockSubmit);
    });

    it('treats null route as unbound form', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, null as any)
      );

      expect(result.current.submit).toBe(mockSubmit);
    });

    it('treats undefined route as unbound form', () => {
      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, undefined)
      );

      expect(result.current.submit).toBe(mockSubmit);
    });

    it('validates method is one of allowed HTTP methods', () => {
      const invalidRoute = {
        url: '/posts/1',
        method: 'invalid',
      } as any;

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, invalidRoute)
      );

      // Should treat as unbound (invalid RouteResult)
      expect(result.current.submit).toBe(mockSubmit);
    });
  });

  describe('real-world usage patterns', () => {
    it('supports typical create form pattern', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const { result } = renderHook(() =>
        useForm(
          {
            title: '',
            content: '',
            published: false,
          },
          route
        )
      );

      act(() => {
        result.current.submit({
          preserveScroll: true,
          onSuccess: () => console.log('Created!'),
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', {
        preserveScroll: true,
        onSuccess: expect.any(Function),
      });
    });

    it('supports typical edit form pattern', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm(
          {
            title: 'Existing Post',
            content: 'Existing content',
            published: true,
          },
          route
        )
      );

      act(() => {
        result.current.submit({
          preserveScroll: true,
          onSuccess: () => console.log('Updated!'),
          onError: (errors) => console.log('Errors:', errors),
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        preserveScroll: true,
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
      });
    });

    it('supports typical delete confirmation pattern', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const { result } = renderHook(() => useForm({}, route));

      act(() => {
        result.current.submit({
          onBefore: () => confirm('Are you sure?'),
          onSuccess: () => console.log('Deleted!'),
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('delete', '/posts/1', {
        onBefore: expect.any(Function),
        onSuccess: expect.any(Function),
      });
    });

    it('supports file upload with progress tracking', () => {
      const route: RouteResult = {
        url: '/posts/1/upload',
        method: 'post',
      };

      const { result } = renderHook(() =>
        useForm(
          {
            file: new File(['content'], 'test.txt'),
          },
          route
        )
      );

      act(() => {
        result.current.submit({
          forceFormData: true,
          onProgress: (progress) => console.log(progress),
        });
      });

      expect(mockSubmit).toHaveBeenCalledWith('post', '/posts/1/upload', {
        forceFormData: true,
        onProgress: expect.any(Function),
      });
    });
  });

  describe('form state management', () => {
    it('exposes errors object', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.errors).toBeDefined();
    });

    it('exposes processing state', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.processing).toBeDefined();
    });

    it('exposes progress state', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.progress).toBeDefined();
    });

    it('exposes wasSuccessful state', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.wasSuccessful).toBeDefined();
    });

    it('exposes recentlySuccessful state', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.recentlySuccessful).toBeDefined();
    });

    it('exposes isDirty state', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const { result } = renderHook(() =>
        useForm({ title: 'Test' }, route)
      );

      expect(result.current.isDirty).toBeDefined();
    });
  });
});
