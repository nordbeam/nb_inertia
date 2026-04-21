import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { InitialModalHandler, ModalStackProvider, useModalStack } from '../modals';

let pageProps: Record<string, unknown> = {};
const listeners = new Map<string, (event: any) => void>();

vi.mock('@inertiajs/react', () => ({
  usePage: () => ({ props: pageProps }),
  router: {
    on: (event: string, callback: (event: any) => void) => {
      listeners.set(event, callback);
      return () => listeners.delete(event);
    },
  },
}));

function StackInspector() {
  const { modals } = useModalStack();
  const name = (modals[0]?.props as { user?: { name?: string } } | undefined)?.user?.name ?? 'none';

  return <div data-testid="modal-user-name">{name}</div>;
}

describe('InitialModalHandler (React)', () => {
  beforeEach(() => {
    listeners.clear();
    pageProps = {
      _nb_modal: {
        component: 'Users/Edit',
        props: { user: { name: 'Alice' } },
        url: '/users/1/edit',
        baseUrl: '/users',
      },
    };
  });

  it('updates an existing modal when navigating to the same modal URL', async () => {
    render(
      <ModalStackProvider>
        <InitialModalHandler resolveComponent={async () => () => null} />
        <StackInspector />
      </ModalStackProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('modal-user-name')).toHaveTextContent('Alice');
    });

    listeners.get('navigate')?.({
      detail: {
        page: {
          props: {
            _nb_modal: {
              component: 'Users/Edit',
              props: { user: { name: 'Bob' } },
              url: '/users/1/edit',
              baseUrl: '/users',
            },
          },
        },
      },
    });

    await waitFor(() => {
      expect(screen.getByTestId('modal-user-name')).toHaveTextContent('Bob');
    });
  });
});
