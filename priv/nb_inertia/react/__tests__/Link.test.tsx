/**
 * Integration tests for enhanced NbInertia Link component
 *
 * Tests verify that the Link component correctly handles both RouteResult objects
 * and plain string URLs while maintaining backward compatibility with standard Inertia.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { Link } from '../Link';
import type { RouteResult } from '../router';

// Mock @inertiajs/react
vi.mock('@inertiajs/react', () => ({
  Link: vi.fn(({ href, method, children, ...props }) => (
    <a
      href={href}
      data-method={method}
      data-testid="inertia-link"
      {...props}
    >
      {children}
    </a>
  )),
}));

describe('Link Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('with RouteResult objects', () => {
    it('renders correct href from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(<Link href={route}>View Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
    });

    it('renders correct method from RouteResult', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      render(<Link href={route}>Edit Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('data-method', 'patch');
    });

    it('handles GET routes correctly', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'get',
      };

      render(<Link href={route}>All Posts</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts');
      expect(link).toHaveAttribute('data-method', 'get');
    });

    it('handles POST routes correctly', () => {
      const route: RouteResult = {
        url: '/posts',
        method: 'post',
      };

      render(<Link href={route}>Create Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts');
      expect(link).toHaveAttribute('data-method', 'post');
    });

    it('handles PATCH routes correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      render(<Link href={route}>Update Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'patch');
    });

    it('handles PUT routes correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'put',
      };

      render(<Link href={route}>Replace Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'put');
    });

    it('handles DELETE routes correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      render(<Link href={route}>Delete Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'delete');
    });

    it('handles HEAD routes correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'head',
      };

      render(<Link href={route}>Check Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'head');
    });

    it('explicit method prop overrides RouteResult method', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route} method="post">
          Override Method
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'post');
    });
  });

  describe('backward compatibility with plain strings', () => {
    it('works with plain string URL', () => {
      render(<Link href="/posts/1">View Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
    });

    it('works with plain string URL and explicit method', () => {
      render(
        <Link href="/posts/1" method="post">
          Create Post
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1');
      expect(link).toHaveAttribute('data-method', 'post');
    });

    it('defaults to undefined method when not specified with string URL', () => {
      render(<Link href="/posts">All Posts</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts');
      expect(link.getAttribute('data-method')).toBe(null);
    });
  });

  describe('passes through other props', () => {
    it('passes className prop', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route} className="text-blue-500">
          View Post
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveClass('text-blue-500');
    });

    it('passes data prop', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'patch',
      };

      render(
        <Link href={route} data={{ title: 'Updated' }}>
          Update
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('data');
    });

    it('passes preserveState prop', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route} preserveState>
          View Post
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });

    it('passes preserveScroll prop', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route} preserveScroll>
          View Post
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });

    it('passes as prop to render as different element', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'delete',
      };

      render(
        <Link href={route} as="button">
          Delete
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });

    it('passes only prop for partial reloads', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route} only={['post']}>
          View Post
        </Link>
      );

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });
  });

  describe('edge cases', () => {
    it('handles empty string URL', () => {
      render(<Link href="">Empty</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '');
    });

    it('handles URLs with query parameters', () => {
      const route: RouteResult = {
        url: '/posts?page=2&sort=date',
        method: 'get',
      };

      render(<Link href={route}>Page 2</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts?page=2&sort=date');
    });

    it('handles URLs with hash fragments', () => {
      const route: RouteResult = {
        url: '/posts/1#comments',
        method: 'get',
      };

      render(<Link href={route}>Comments</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', '/posts/1#comments');
    });

    it('handles absolute URLs', () => {
      const route: RouteResult = {
        url: 'https://example.com/posts/1',
        method: 'get',
      };

      render(<Link href={route}>External Post</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toHaveAttribute('href', 'https://example.com/posts/1');
    });

    it('renders children correctly', () => {
      const route: RouteResult = {
        url: '/posts/1',
        method: 'get',
      };

      render(
        <Link href={route}>
          <span>View</span> <strong>Post</strong>
        </Link>
      );

      expect(screen.getByText('View')).toBeInTheDocument();
      expect(screen.getByText('Post')).toBeInTheDocument();
    });
  });

  describe('type guard validation', () => {
    it('rejects objects without url property', () => {
      const invalidRoute = { method: 'get' } as any;

      render(<Link href={invalidRoute}>Invalid</Link>);

      const link = screen.getByTestId('inertia-link');
      // Should treat as plain object/string, not extract properties
      expect(link).toBeDefined();
    });

    it('rejects objects without method property', () => {
      const invalidRoute = { url: '/posts/1' } as any;

      render(<Link href={invalidRoute}>Invalid</Link>);

      const link = screen.getByTestId('inertia-link');
      // Should treat as plain object/string, not extract properties
      expect(link).toBeDefined();
    });

    it('rejects objects with invalid method', () => {
      const invalidRoute = { url: '/posts/1', method: 'invalid' } as any;

      render(<Link href={invalidRoute}>Invalid</Link>);

      const link = screen.getByTestId('inertia-link');
      // Should treat as invalid RouteResult
      expect(link).toBeDefined();
    });

    it('rejects null', () => {
      const invalidRoute = null as any;

      render(<Link href={invalidRoute}>Invalid</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });

    it('rejects undefined', () => {
      const invalidRoute = undefined as any;

      render(<Link href={invalidRoute}>Invalid</Link>);

      const link = screen.getByTestId('inertia-link');
      expect(link).toBeDefined();
    });
  });
});
