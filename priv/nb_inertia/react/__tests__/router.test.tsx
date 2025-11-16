/**
 * Integration tests for enhanced NbInertia router
 *
 * Tests verify that the router correctly handles both RouteResult objects
 * and plain string URLs while maintaining backward compatibility with standard Inertia.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { router } from '../router';
import type { RouteResult } from '../router';

// Mock the Inertia router - use factory function to avoid hoisting issues
vi.mock('@inertiajs/react', () => {
  const mockVisit = vi.fn();
  const mockGet = vi.fn();
  const mockPost = vi.fn();
  const mockPut = vi.fn();
  const mockPatch = vi.fn();
  const mockDelete = vi.fn();

  return {
    router: {
      visit: mockVisit,
      get: mockGet,
      post: mockPost,
      put: mockPut,
      patch: mockPatch,
      delete: mockDelete,
      on: vi.fn(),
      reload: vi.fn(),
      replace: vi.fn(),
      remember: vi.fn(),
      restore: vi.fn(),
    },
  };
});

// Import the mock functions after vi.mock
import { router as inertiaRouter } from '@inertiajs/react';
const mockVisit = inertiaRouter.visit as ReturnType<typeof vi.fn>;
const mockGet = inertiaRouter.get as ReturnType<typeof vi.fn>;
const mockPost = inertiaRouter.post as ReturnType<typeof vi.fn>;
const mockPut = inertiaRouter.put as ReturnType<typeof vi.fn>;
const mockPatch = inertiaRouter.patch as ReturnType<typeof vi.fn>;
const mockDelete = inertiaRouter.delete as ReturnType<typeof vi.fn>;

describe('router', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('visit() with RouteResult', () => {
    it('calls Inertia router.visit with correct URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.visit(route);

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method: 'get' });
    });

    it('uses method from RouteResult when no explicit method in options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.visit(route);

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method: 'patch' });
    });

    it('preserves explicit method in options over RouteResult method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.visit(route, { method: 'post' });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method: 'post' });
    });

    it('passes through additional options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.visit(route, {
        preserveState: true,
        preserveScroll: true,
        only: ['post'],
      });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {
        method: 'get',
        preserveState: true,
        preserveScroll: true,
        only: ['post'],
      });
    });

    it('handles all HTTP methods correctly', () => {
      const methods: Array<RouteResult['method']> = [
        'get',
        'post',
        'put',
        'patch',
        'delete',
        'head',
      ];

      methods.forEach((method) => {
        vi.clearAllMocks();
        const route: RouteResult = {
          url: '/posts/1',
          method,
        };

        router.visit(route);

        expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method });
      });
    });

    it('handles RouteResult with data in options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.visit(route, {
        data: { title: 'Updated Title' },
      });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {
        method: 'patch',
        data: { title: 'Updated Title' },
      });
    });
  });

  describe('visit() with plain strings (backward compatibility)', () => {
    it('works with plain string URL', () => {
      router.visit('/posts/1');

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {});
    });

    it('works with plain string URL and explicit method', () => {
      router.visit('/posts/1', { method: 'post' });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method: 'post' });
    });

    it('passes through all options with string URL', () => {
      router.visit('/posts/1', {
        method: 'post',
        data: { title: 'New Post' },
        preserveState: true,
        preserveScroll: true,
      });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {
        method: 'post',
        data: { title: 'New Post' },
        preserveState: true,
        preserveScroll: true,
      });
    });
  });

  describe('get() method', () => {
    it('calls Inertia router.get with URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.get(route);

      expect(mockGet).toHaveBeenCalledWith('/posts/1', {});
    });

    it('works with plain string URL', () => {
      router.get('/posts/1');

      expect(mockGet).toHaveBeenCalledWith('/posts/1', {});
    });

    it('passes through options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.get(route, {
        preserveState: true,
        only: ['post'],
      });

      expect(mockGet).toHaveBeenCalledWith('/posts/1', {
        preserveState: true,
        only: ['post'],
      });
    });
  });

  describe('post() method', () => {
    it('calls Inertia router.post with URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      router.post(route, { title: 'New Post' });

      expect(mockPost).toHaveBeenCalledWith('/posts', { title: 'New Post' }, {});
    });

    it('works with plain string URL', () => {
      router.post('/posts', { title: 'New Post' });

      expect(mockPost).toHaveBeenCalledWith('/posts', { title: 'New Post' }, {});
    });

    it('handles empty data object', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      router.post(route);

      expect(mockPost).toHaveBeenCalledWith('/posts', {}, {});
    });

    it('passes through options', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      router.post(
        route,
        { title: 'New Post' },
        {
          preserveState: true,
          preserveScroll: true,
        }
      );

      expect(mockPost).toHaveBeenCalledWith(
        '/posts',
        { title: 'New Post' },
        {
          preserveState: true,
          preserveScroll: true,
        }
      );
    });
  });

  describe('put() method', () => {
    it('calls Inertia router.put with URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      router.put(route, { title: 'Replaced Post' });

      expect(mockPut).toHaveBeenCalledWith('/posts/1', { title: 'Replaced Post' }, {});
    });

    it('works with plain string URL', () => {
      router.put('/posts/1', { title: 'Replaced Post' });

      expect(mockPut).toHaveBeenCalledWith('/posts/1', { title: 'Replaced Post' }, {});
    });

    it('handles empty data object', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      router.put(route);

      expect(mockPut).toHaveBeenCalledWith('/posts/1', {}, {});
    });

    it('passes through options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      router.put(
        route,
        { title: 'Replaced Post' },
        {
          preserveState: false,
        }
      );

      expect(mockPut).toHaveBeenCalledWith(
        '/posts/1',
        { title: 'Replaced Post' },
        {
          preserveState: false,
        }
      );
    });
  });

  describe('patch() method', () => {
    it('calls Inertia router.patch with URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.patch(route, { title: 'Updated Post' });

      expect(mockPatch).toHaveBeenCalledWith('/posts/1', { title: 'Updated Post' }, {});
    });

    it('works with plain string URL', () => {
      router.patch('/posts/1', { title: 'Updated Post' });

      expect(mockPatch).toHaveBeenCalledWith('/posts/1', { title: 'Updated Post' }, {});
    });

    it('handles empty data object', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.patch(route);

      expect(mockPatch).toHaveBeenCalledWith('/posts/1', {}, {});
    });

    it('passes through options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.patch(
        route,
        { title: 'Updated Post' },
        {
          preserveScroll: true,
          onSuccess: () => console.log('Success'),
        }
      );

      expect(mockPatch).toHaveBeenCalledWith(
        '/posts/1',
        { title: 'Updated Post' },
        {
          preserveScroll: true,
          onSuccess: expect.any(Function),
        }
      );
    });
  });

  describe('delete() method', () => {
    it('calls Inertia router.delete with URL from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      router.delete(route);

      expect(mockDelete).toHaveBeenCalledWith('/posts/1', {});
    });

    it('works with plain string URL', () => {
      router.delete('/posts/1');

      expect(mockDelete).toHaveBeenCalledWith('/posts/1', {});
    });

    it('passes through options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      router.delete(route, {
        preserveState: false,
        onBefore: () => confirm('Are you sure?'),
      });

      expect(mockDelete).toHaveBeenCalledWith('/posts/1', {
        preserveState: false,
        onBefore: expect.any(Function),
      });
    });
  });

  describe('edge cases', () => {
    it('handles empty string URL', () => {
      router.visit('');

      expect(mockVisit).toHaveBeenCalledWith('', {});
    });

    it('handles URLs with query parameters', () => {
      const route: RouteResult = {
        url: '/posts?page=2&sort=date',
        method: 'get',
      };

      router.visit(route);

      expect(mockVisit).toHaveBeenCalledWith('/posts?page=2&sort=date', {
        method: 'get',
      });
    });

    it('handles URLs with hash fragments', () => {
      const route: RouteResult = {
        url: '/posts/1#comments',
        method: 'get',
      };

      router.visit(route);

      expect(mockVisit).toHaveBeenCalledWith('/posts/1#comments', {
        method: 'get',
      });
    });

    it('handles absolute URLs', () => {
      const route: RouteResult = {
        url: 'https://example.com/posts/1',
        method: 'get',
      };

      router.visit(route);

      expect(mockVisit).toHaveBeenCalledWith('https://example.com/posts/1', {
        method: 'get',
      });
    });

    it('handles complex data objects', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const complexData = {
        title: 'New Post',
        tags: ['tag1', 'tag2'],
        metadata: {
          author: 'John Doe',
          date: '2024-01-01',
        },
      };

      router.post(route, complexData);

      expect(mockPost).toHaveBeenCalledWith('/posts', complexData, {});
    });
  });

  describe('preserves all Inertia router properties', () => {
    it('exposes all original router methods', () => {
      expect(router.visit).toBeDefined();
      expect(router.get).toBeDefined();
      expect(router.post).toBeDefined();
      expect(router.put).toBeDefined();
      expect(router.patch).toBeDefined();
      expect(router.delete).toBeDefined();
      expect(router.on).toBeDefined();
      expect(router.reload).toBeDefined();
      expect(router.replace).toBeDefined();
      expect(router.remember).toBeDefined();
      expect(router.restore).toBeDefined();
    });
  });

  describe('type guard validation', () => {
    it('correctly identifies valid RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      router.visit(route);

      // Should extract URL and method
      expect(mockVisit).toHaveBeenCalledWith('/posts/1', { method: 'get' });
    });

    it('handles invalid RouteResult gracefully', () => {
      const invalidRoute = { url: '/posts/1' } as any;

      router.visit(invalidRoute);

      // Should treat as non-RouteResult
      expect(mockVisit).toHaveBeenCalled();
    });
  });

  describe('options merging', () => {
    it('merges RouteResult method with other options', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      router.visit(route, {
        data: { title: 'Updated' },
        preserveState: true,
        preserveScroll: true,
        only: ['post'],
        headers: { 'X-Custom': 'value' },
        errorBag: 'post',
        forceFormData: false,
        queryStringArrayFormat: 'brackets',
        async: true,
        replace: false,
        preserveUrl: false,
      });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {
        method: 'patch',
        data: { title: 'Updated' },
        preserveState: true,
        preserveScroll: true,
        only: ['post'],
        headers: { 'X-Custom': 'value' },
        errorBag: 'post',
        forceFormData: false,
        queryStringArrayFormat: 'brackets',
        async: true,
        replace: false,
        preserveUrl: false,
      });
    });
  });

  describe('callback options', () => {
    it('preserves onBefore callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const onBefore = vi.fn();

      router.delete(route, { onBefore });

      expect(mockDelete).toHaveBeenCalledWith('/posts/1', {
        onBefore,
      });
    });

    it('preserves onStart callback', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'get',
      };

      const onStart = vi.fn();

      router.visit(route, { onStart });

      expect(mockVisit).toHaveBeenCalledWith('/posts', {
        method: 'get',
        onStart,
      });
    });

    it('preserves onProgress callback', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const onProgress = vi.fn();

      router.post(route, { file: new File([], 'test.txt') }, { onProgress });

      expect(mockPost).toHaveBeenCalledWith(
        '/posts',
        { file: expect.any(File) },
        {
          onProgress,
        }
      );
    });

    it('preserves onSuccess callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const onSuccess = vi.fn();

      router.patch(route, { title: 'Updated' }, { onSuccess });

      expect(mockPatch).toHaveBeenCalledWith(
        '/posts/1',
        { title: 'Updated' },
        {
          onSuccess,
        }
      );
    });

    it('preserves onError callback', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const onError = vi.fn();

      router.post(route, { title: 'New Post' }, { onError });

      expect(mockPost).toHaveBeenCalledWith(
        '/posts',
        { title: 'New Post' },
        {
          onError,
        }
      );
    });

    it('preserves onCancel callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      const onCancel = vi.fn();

      router.visit(route, { onCancel });

      expect(mockVisit).toHaveBeenCalledWith('/posts/1', {
        method: 'get',
        onCancel,
      });
    });

    it('preserves onFinish callback', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const onFinish = vi.fn();

      router.delete(route, { onFinish });

      expect(mockDelete).toHaveBeenCalledWith('/posts/1', {
        onFinish,
      });
    });
  });
});
