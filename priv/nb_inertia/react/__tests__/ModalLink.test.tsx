import React from 'react';
import { createEvent, fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vite-plus/test';
import { ModalLink } from '../modals/ModalLink';

const { mockVisitModal } = vi.hoisted(() => ({
  mockVisitModal: vi.fn(),
}));

vi.mock('../modals/modalStack', () => ({
  useModalStack: () => ({
    modals: [],
    prefetchModal: undefined,
    visitModal: mockVisitModal,
  }),
}));

describe('ModalLink', () => {
  it('leaves links with alternate targets to the browser', () => {
    render(
      <ModalLink href="/users/1" target="_blank">
        Open user
      </ModalLink>
    );

    const link = screen.getByRole('link', { name: 'Open user' });
    const event = createEvent.click(link);
    fireEvent(link, event);

    expect(event.defaultPrevented).toBe(false);
    expect(mockVisitModal).not.toHaveBeenCalled();
  });

  it('intercepts ordinary clicks after invoking the caller callback', () => {
    const onClick = vi.fn();

    render(
      <ModalLink href="/users/1" onClick={onClick}>
        Open user
      </ModalLink>
    );

    const link = screen.getByRole('link', { name: 'Open user' });
    const event = createEvent.click(link);
    fireEvent(link, event);

    expect(onClick).toHaveBeenCalledTimes(1);
    expect(event.defaultPrevented).toBe(true);
    expect(mockVisitModal).toHaveBeenCalledWith(
      '/users/1',
      expect.objectContaining({ method: 'get' })
    );
  });
});
