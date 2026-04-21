import React, { useEffect } from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ModalRenderer, ModalStackProvider, useModalStack } from '../modals';

const mockVisit = vi.fn();
const mockOn = vi.fn(() => () => {});

vi.mock('@inertiajs/react', () => ({
  router: {
    visit: (...args: unknown[]) => mockVisit(...args),
    on: (...args: unknown[]) => mockOn(...args),
  },
}));

function ExampleModal() {
  return <div>Modal content</div>;
}

function Harness({ closeOnClickOutside = true }: { closeOnClickOutside?: boolean }) {
  const { pushModal } = useModalStack();

  useEffect(() => {
    pushModal({
      component: ExampleModal,
      componentName: 'Users/Edit',
      props: {},
      url: '/users/1/edit',
      config: { closeOnClickOutside },
      baseUrl: '/users',
      returnUrl: '/users?page=2',
    });
  }, [closeOnClickOutside, pushModal]);

  return <ModalRenderer />;
}

describe('ModalRenderer (React)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('closes on backdrop click by default', async () => {
    const { container } = render(
      <ModalStackProvider>
        <Harness />
      </ModalStackProvider>
    );

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    const backdrop = container.querySelector('[aria-hidden="true"]');
    expect(backdrop).not.toBeNull();

    fireEvent.click(backdrop!);

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    });
  });

  it('keeps the modal open when backdrop closing is disabled', async () => {
    const { container } = render(
      <ModalStackProvider>
        <Harness closeOnClickOutside={false} />
      </ModalStackProvider>
    );

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    const backdrop = container.querySelector('[aria-hidden="true"]');
    expect(backdrop).not.toBeNull();

    fireEvent.click(backdrop!);

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });
  });
});
