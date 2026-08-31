import React from 'react';
import { render } from '@testing-library/react';
import { describe, expect, it, vi } from 'vite-plus/test';
import { Head } from '../Head';
import { ModalPageProvider } from '../modals/modalStack';

const { mockInertiaHead } = vi.hoisted(() => ({
  mockInertiaHead: vi.fn(({ children }: { children?: React.ReactNode }) => (
    <div data-testid="official-head">{children}</div>
  )),
}));

vi.mock('@inertiajs/react', () => ({
  Head: mockInertiaHead,
}));

describe('enhanced React Head', () => {
  it('delegates title and child head elements to the official manager', () => {
    render(
      <Head title="Users">
        <meta name="description" content="Users" />
        <link rel="canonical" href="/users" />
      </Head>,
    );

    expect(mockInertiaHead.mock.calls[0]?.[0]).toEqual(expect.objectContaining({ title: 'Users' }));
    const children = React.Children.toArray(mockInertiaHead.mock.calls[0]?.[0].children);
    expect(children).toHaveLength(2);
    expect((children[0] as React.ReactElement).type).toBe('meta');
    expect((children[1] as React.ReactElement).type).toBe('link');
  });

  it('owns fallback head elements safely when a standalone modal has no head context', () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    mockInertiaHead.mockImplementation(() => {
      throw new Error('head context unavailable');
    });

    const { unmount } = render(
      <ModalPageProvider component="Users/Show" props={{}} url="/users/1">
        <Head title="User">
          <meta name="description" content="User details" />
        </Head>
      </ModalPageProvider>,
    );

    expect(document.head.querySelector('meta[name="description"]')).toHaveAttribute(
      'content',
      'User details',
    );
    expect(document.head.querySelector('title[data-nb-inertia-modal-head]')).toHaveTextContent(
      'User',
    );
    expect(document.head.querySelector('[data-inertia]')).toBeNull();

    // Inertia's head reconciler removes non-Inertia titles on navigation.
    // The modal cleanup must tolerate the node already being detached.
    document.head.querySelector('title[data-nb-inertia-modal-head]')?.remove();

    expect(() => unmount()).not.toThrow();
    expect(document.head.querySelector('meta[name="description"]')).toBeNull();
    expect(document.head.querySelector('title[data-nb-inertia-modal-head]')).toBeNull();

    consoleError.mockRestore();
    mockInertiaHead.mockImplementation(({ children }: { children?: React.ReactNode }) => (
      <div data-testid="official-head">{children}</div>
    ));
  });
});
