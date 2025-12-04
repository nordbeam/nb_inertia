/**
 * Integration tests for enhanced NbInertia useForm composable (Vue)
 *
 * Tests verify that the useForm composable correctly handles optional route binding,
 * provides simplified submit() when bound, and maintains backward compatibility
 * with standard Inertia useForm when not bound.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useForm } from '../useForm';
import type { RouteResult } from '../../shared/types';

// Mock Inertia useForm
const mockSubmit = vi.fn();
const mockSetData = vi.fn();
const mockTransform = vi.fn();
const mockReset = vi.fn();
const mockClearErrors = vi.fn();

vi.mock('@inertiajs/vue3', () => ({
  useForm: vi.fn((initialData) => ({
    data: vi.fn(() => initialData),
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

describe('useForm Composable (Vue)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('when bound to a route', () => {
    it('returns form with enhanced submit method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.submit).toBeDefined();
    });

    it('submit() uses route URL and method without arguments', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', undefined);
    });

    it('submit() accepts visit options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);
      form.submit({
        preserveScroll: true,
        preserveState: true,
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

      const form = useForm({ search: 'test' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('get', '/posts', undefined);
    });

    it('works with POST method', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const form = useForm({ title: 'New Post' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('post', '/posts', undefined);
    });

    it('works with PUT method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      const form = useForm({ title: 'Replaced Post' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('put', '/posts/1', undefined);
    });

    it('works with PATCH method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Updated Post' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', undefined);
    });

    it('works with DELETE method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const form = useForm({}, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith('delete', '/posts/1', undefined);
    });

    it('preserves all other form properties', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.data).toBeDefined();
      expect(form.setData).toBeDefined();
      expect(form.transform).toBeDefined();
      expect(form.reset).toBeDefined();
      expect(form.clearErrors).toBeDefined();
      expect(form.errors).toBeDefined();
      expect(form.processing).toBeDefined();
      expect(form.wasSuccessful).toBeDefined();
      expect(form.recentlySuccessful).toBeDefined();
      expect(form.isDirty).toBeDefined();
    });

    it('submit() passes through onSuccess callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const onSuccess = vi.fn();
      const form = useForm({ title: 'Test Post' }, route);
      form.submit({ onSuccess });

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
      const form = useForm({ title: 'Test Post' }, route);
      form.submit({ onError });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        onError,
      });
    });

    it('submit() passes through all visit options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);
      const options = {
        preserveScroll: true,
        preserveState: true,
        only: ['post'],
        headers: { 'X-Custom': 'value' },
        onBefore: vi.fn(),
        onStart: vi.fn(),
        onProgress: vi.fn(),
        onSuccess: vi.fn(),
        onError: vi.fn(),
        onCancel: vi.fn(),
        onFinish: vi.fn(),
      };

      form.submit(options);

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', options);
    });
  });

  describe('when not bound to a route', () => {
    it('returns standard Inertia form', () => {
      const form = useForm({ title: 'Test Post' });

      expect(form.submit).toBe(mockSubmit);
    });

    it('submit() requires method and URL parameters', () => {
      const form = useForm({ title: 'Test Post' });

      // Standard Inertia useForm signature
      form.submit('patch', '/posts/1');

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1');
    });

    it('submit() accepts options as third parameter', () => {
      const form = useForm({ title: 'Test Post' });

      form.submit('patch', '/posts/1', {
        preserveScroll: true,
      });

      expect(mockSubmit).toHaveBeenCalledWith('patch', '/posts/1', {
        preserveScroll: true,
      });
    });

    it('preserves all standard useForm properties', () => {
      const form = useForm({ title: 'Test Post' });

      expect(form.data).toBeDefined();
      expect(form.setData).toBeDefined();
      expect(form.transform).toBeDefined();
      expect(form.reset).toBeDefined();
      expect(form.clearErrors).toBeDefined();
      expect(form.errors).toBeDefined();
      expect(form.processing).toBeDefined();
      expect(form.wasSuccessful).toBeDefined();
      expect(form.recentlySuccessful).toBeDefined();
      expect(form.isDirty).toBeDefined();
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

      const form = useForm(initialData, route);

      expect(form.data()).toEqual(initialData);
    });

    it('setData is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.setData).toBe(mockSetData);
    });

    it('transform is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.transform).toBe(mockTransform);
    });

    it('reset is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.reset).toBe(mockReset);
    });

    it('clearErrors is accessible and functional', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const form = useForm({ title: 'Test Post' }, route);

      expect(form.clearErrors).toBe(mockClearErrors);
    });
  });

  describe('edge cases', () => {
    it('handles empty data object', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const form = useForm({}, route);

      expect(form.data()).toEqual({});
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

      const form = useForm(complexData, route);

      expect(form.data()).toEqual(complexData);
    });

    it('handles URLs with query parameters', () => {
      const route: RouteResult = {
        url: '/posts?category=tech&page=2',
        method: 'get',
      };

      const form = useForm({ search: 'test' }, route);
      form.submit();

      expect(mockSubmit).toHaveBeenCalledWith(
        'get',
        '/posts?category=tech&page=2',
        undefined
      );
    });
  });

  describe('type guard validation', () => {
    it('treats invalid RouteResult as unbound form', () => {
      const invalidRoute = { url: '/posts/1' } as any;

      const form = useForm({ title: 'Test' }, invalidRoute);

      // Should return standard Inertia form (unbound)
      expect(form.submit).toBe(mockSubmit);
    });

    it('treats null route as unbound form', () => {
      const form = useForm({ title: 'Test' }, null as any);

      expect(form.submit).toBe(mockSubmit);
    });

    it('treats undefined route as unbound form', () => {
      const form = useForm({ title: 'Test' }, undefined);

      expect(form.submit).toBe(mockSubmit);
    });

    it('validates method is one of allowed HTTP methods', () => {
      const invalidRoute = {
        url: '/posts/1',
        method: 'invalid',
      } as any;

      const form = useForm({ title: 'Test' }, invalidRoute);

      // Should treat as unbound (invalid RouteResult)
      expect(form.submit).toBe(mockSubmit);
    });
  });

  describe('real-world usage patterns', () => {
    it('supports typical create form pattern', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const form = useForm(
        {
          title: '',
          content: '',
          published: false,
        },
        route
      );

      form.submit({
        preserveScroll: true,
        onSuccess: () => console.log('Created!'),
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

      const form = useForm(
        {
          title: 'Existing Post',
          content: 'Existing content',
          published: true,
        },
        route
      );

      form.submit({
        preserveScroll: true,
        onSuccess: () => console.log('Updated!'),
        onError: (errors) => console.log('Errors:', errors),
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

      const form = useForm({}, route);

      form.submit({
        onBefore: () => confirm('Are you sure?'),
        onSuccess: () => console.log('Deleted!'),
      });

      expect(mockSubmit).toHaveBeenCalledWith('delete', '/posts/1', {
        onBefore: expect.any(Function),
        onSuccess: expect.any(Function),
      });
    });
  });
});
