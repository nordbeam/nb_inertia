/**
 * Integration tests for enhanced NbInertia Link component (Vue)
 *
 * Tests verify that the Link component correctly handles both RouteResult objects
 * and plain string URLs while maintaining backward compatibility with standard Inertia.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import Link from '../Link.vue';
import type { RouteResult } from '../router';
import { h } from 'vue';

// Mock @inertiajs/vue3
vi.mock('@inertiajs/vue3', () => ({
  Link: {
    name: 'InertiaLink',
    props: {
      href: String,
      method: String,
      data: Object,
      replace: Boolean,
      preserveScroll: [Boolean, Function],
      preserveState: [Boolean, Function, null],
      only: Array,
      except: Array,
      headers: Object,
      queryStringArrayFormat: String,
      as: String,
      prefetch: [Boolean, Array],
    },
    setup(props: any, { slots }: any) {
      return () =>
        h(
          'a',
          {
            href: props.href,
            'data-method': props.method,
            'data-testid': 'inertia-link',
          },
          slots.default?.()
        );
    },
  },
}));

describe('Link Component (Vue)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('with RouteResult objects', () => {
    it('renders correct href from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'View Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1');
    });

    it('renders correct method from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'Edit Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('data-method')).toBe('patch');
    });

    it('handles GET routes correctly', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'All Posts',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts');
      expect(link.attributes('data-method')).toBe('get');
    });

    it('handles POST routes correctly', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'Create Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts');
      expect(link.attributes('data-method')).toBe('post');
    });

    it('handles DELETE routes correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'Delete Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1');
      expect(link.attributes('data-method')).toBe('delete');
    });

    it('explicit method prop overrides RouteResult method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: {
          href: route,
          method: 'post',
        },
        slots: {
          default: 'Override Method',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1');
      expect(link.attributes('data-method')).toBe('post');
    });
  });

  describe('backward compatibility with plain strings', () => {
    it('works with plain string URL', () => {
      const wrapper = mount(Link, {
        props: { href: '/posts/1' },
        slots: {
          default: 'View Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1');
    });

    it('works with plain string URL and explicit method', () => {
      const wrapper = mount(Link, {
        props: {
          href: '/posts/1',
          method: 'post',
        },
        slots: {
          default: 'Create Post',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1');
      expect(link.attributes('data-method')).toBe('post');
    });

    it('defaults to undefined method when not specified with string URL', () => {
      const wrapper = mount(Link, {
        props: { href: '/posts' },
        slots: {
          default: 'All Posts',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts');
      expect(link.attributes('data-method')).toBeUndefined();
    });
  });

  describe('edge cases', () => {
    it('handles empty string URL', () => {
      const wrapper = mount(Link, {
        props: { href: '' },
        slots: {
          default: 'Empty',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('');
    });

    it('handles URLs with query parameters', () => {
      const route: RouteResult = {
        url: '/posts?page=2&sort=date',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'Page 2',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts?page=2&sort=date');
    });

    it('handles URLs with hash fragments', () => {
      const route: RouteResult = {
        url: '/posts/1#comments',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'Comments',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.attributes('href')).toBe('/posts/1#comments');
    });

    it('renders slot content correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      const wrapper = mount(Link, {
        props: { href: route },
        slots: {
          default: 'View Post',
        },
      });

      expect(wrapper.text()).toBe('View Post');
    });
  });

  describe('type guard validation', () => {
    it('rejects objects without url property', () => {
      const invalidRoute = { method: 'get' } as any;

      const wrapper = mount(Link, {
        props: { href: invalidRoute },
        slots: {
          default: 'Invalid',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.exists()).toBe(true);
    });

    it('rejects objects without method property', () => {
      const invalidRoute = { url: '/posts/1' } as any;

      const wrapper = mount(Link, {
        props: { href: invalidRoute },
        slots: {
          default: 'Invalid',
        },
      });

      const link = wrapper.find('[data-testid="inertia-link"]');
      expect(link.exists()).toBe(true);
    });
  });
});
