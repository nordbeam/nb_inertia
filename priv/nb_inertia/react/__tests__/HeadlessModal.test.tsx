import React, { useEffect } from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { Modal, ModalStackProvider, useModalStack, useCurrentModal, HeadlessModal } from '../modals';

const mockVisit = vi.fn();
const mockOn = vi.fn(() => () => {});

vi.mock('@inertiajs/react', () => ({
  router: {
    visit: (...args: unknown[]) => mockVisit(...args),
    on: (...args: unknown[]) => mockOn(...args),
    reload: (...args: unknown[]) => mockVisit(...args),
  },
}));

function ModalControls() {
  const modal = useCurrentModal();

  return (
    <div>
      <span data-testid="modal-id">{modal.id}</span>
      <span data-testid="modal-index">{modal.index}</span>
      <span data-testid="modal-top">{String(modal.onTopOfStack)}</span>
      <button onClick={() => modal.reload({ only: ['permissions'] })}>Reload</button>
      <button onClick={modal.close}>Close</button>
    </div>
  );
}

function Harness() {
  const { modals, popModal, pushModal } = useModalStack();

  useEffect(() => {
    pushModal({
      component: () => null,
      componentName: 'Users/Edit',
      props: { user: { id: 1 } },
      url: '/users/1/edit',
      config: {},
      baseUrl: '/users',
      returnUrl: '/users?page=2',
    });
  }, [pushModal]);

  const modal = modals[0];

  if (!modal) {
    return <div data-testid="empty-state">empty</div>;
  }

  return (
    <HeadlessModal modal={modal} onClose={() => popModal(modal.id)}>
      {() => (
        <Modal>
          <ModalControls />
        </Modal>
      )}
    </HeadlessModal>
  );
}

function RelationshipControls() {
  const modal = useCurrentModal();
  const parent = modal.getParentModal();
  const child = modal.getChildModal();

  return (
    <div>
      <span data-testid="relationship-modal-id">{modal.id}</span>
      <span data-testid="relationship-parent-id">{parent?.id ?? 'none'}</span>
      <span data-testid="relationship-child-id">{child?.id ?? 'none'}</span>
    </div>
  );
}

function RelationshipHarness() {
  const { modals, popModal, pushModal } = useModalStack();

  useEffect(() => {
    pushModal({
      component: () => null,
      componentName: 'Users/Edit',
      props: { user: { id: 1 } },
      url: '/users/1/edit',
      config: {},
      baseUrl: '/users',
      returnUrl: '/users?page=2',
    });

    pushModal({
      component: () => null,
      componentName: 'Users/Permissions',
      props: { user: { id: 1 } },
      url: '/users/1/permissions',
      config: {},
      baseUrl: '/users/1/edit',
      returnUrl: '/users?page=2',
    });
  }, [pushModal]);

  const modal = modals[1];

  if (!modal) {
    return null;
  }

  return (
    <HeadlessModal modal={modal} onClose={() => popModal(modal.id)}>
      {() => (
        <Modal>
          <RelationshipControls />
        </Modal>
      )}
    </HeadlessModal>
  );
}

describe('HeadlessModal (React)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('provides modal controls and metadata to modal content', async () => {
    render(
      <ModalStackProvider>
        <Harness />
      </ModalStackProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('modal-id')).toHaveTextContent('modal-0');
    });

    expect(screen.getByTestId('modal-index')).toHaveTextContent('0');
    expect(screen.getByTestId('modal-top')).toHaveTextContent('true');

    fireEvent.click(screen.getByText('Reload'));

    expect(mockVisit).toHaveBeenCalledWith(
      '/users/1/edit',
      expect.objectContaining({
        only: ['permissions'],
        preserveState: true,
        preserveScroll: true,
        headers: {
          'x-inertia-modal': 'true',
          'x-inertia-modal-base-url': '/users?page=2',
        },
      })
    );

    fireEvent.click(screen.getByText('Close'));

    await waitFor(() => {
      expect(screen.getByTestId('empty-state')).toHaveTextContent('empty');
    });
  });

  it('exposes parent and child modal handles for stacked modals', async () => {
    render(
      <ModalStackProvider>
        <RelationshipHarness />
      </ModalStackProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('relationship-modal-id')).toHaveTextContent('modal-1');
    });

    expect(screen.getByTestId('relationship-parent-id')).toHaveTextContent('modal-0');
    expect(screen.getByTestId('relationship-child-id')).toHaveTextContent('none');
  });
});
