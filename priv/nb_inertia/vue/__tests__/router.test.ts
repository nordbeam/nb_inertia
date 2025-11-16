/**
 * Integration tests for enhanced NbInertia router (Vue)
 *
 * Tests verify that the router correctly handles both RouteResult objects
 * and plain string URLs while maintaining backward compatibility with standard Inertia.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { router } from '../router';
import type { RouteResult } from '../router';

// Mock the Inertia router - use factory function to avoid hoisting issues
vi.mock('@inertiajs/vue3', () => {
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
import { router as inertiaRouter } from '@inertiajs/vue3';
const mockVisit = inertiaRouter.visit as ReturnType<typeof vi.fn>;
const mockGet = inertiaRouter.get as ReturnType<typeof vi.fn>;
const mockPost = inertiaRouter.post as ReturnType<typeof vi.fn>;
const mockPut = inertiaRouter.put as ReturnType<typeof vi.fn>;
const mockPatch = inertiaRouter.patch as ReturnType<typeof vi.fn>;
const mockDelete = inertiaRouter.delete as ReturnType<typeof vi.fn>;

describe('router (Vue)', () => {
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
});
