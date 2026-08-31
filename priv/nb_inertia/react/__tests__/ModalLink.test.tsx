import React from 'react';
import { createEvent, fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vite-plus/test';
import { ModalLink } from '../modals/ModalLink';

const { mockVisitModal, mockPrefetchModal } = vi.hoisted(() => ({
  mockVisitModal: vi.fn(),
  mockPrefetchModal: vi.fn(),
}));

vi.mock('../modals/modalStack', () => ({
  useModalStack: () => ({
    modals: [],
    prefetchModal: mockPrefetchModal,
    visitModal: mockVisitModal,
  }),
}));

describe('ModalLink', () => {
  it('leaves links with alternate targets to the browser', () => {
    render(
      <ModalLink href="/users/1" target="_blank">
        Open user
      </ModalLink>,
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
      </ModalLink>,
    );

    const link = screen.getByRole('link', { name: 'Open user' });
    const event = createEvent.click(link);
    fireEvent(link, event);

    expect(onClick).toHaveBeenCalledTimes(1);
    expect(event.defaultPrevented).toBe(true);
    expect(mockVisitModal).toHaveBeenCalledWith(
      '/users/1',
      expect.objectContaining({ method: 'get' }),
    );
  });

  it('forwards the complete Inertia 3.7 visit option surface', () => {
    const callbacks = {
      onBefore: vi.fn(),
      onBeforeUpdate: vi.fn(),
      onStart: vi.fn(),
      onProgress: vi.fn(),
      onFinish: vi.fn(),
      onCancel: vi.fn(),
      onSuccess: vi.fn(),
      onError: vi.fn(),
      onHttpException: vi.fn(),
      onNetworkError: vi.fn(),
      onFlash: vi.fn(),
      onPrefetched: vi.fn(),
      onPrefetching: vi.fn(),
    };

    render(
      <ModalLink
        href="/users/1"
        async
        viewTransition
        preserveErrors
        only={['user']}
        except={['audit']}
        reset={['users']}
        invalidateCacheTags={['users']}
        fresh
        preserveUrl
        {...callbacks}
      >
        Open user
      </ModalLink>,
    );

    fireEvent.click(screen.getByRole('link', { name: 'Open user' }));

    expect(mockVisitModal).toHaveBeenCalledWith(
      '/users/1',
      expect.objectContaining({
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ['user'],
        except: ['audit'],
        reset: ['users'],
        invalidateCacheTags: ['users'],
        fresh: true,
        preserveUrl: true,
        onBefore: callbacks.onBefore,
        onBeforeUpdate: callbacks.onBeforeUpdate,
        onStart: callbacks.onStart,
        onProgress: callbacks.onProgress,
        onFinish: callbacks.onFinish,
        onCancel: callbacks.onCancel,
        onSuccess: callbacks.onSuccess,
        onError: callbacks.onError,
        onHttpException: callbacks.onHttpException,
        onNetworkError: callbacks.onNetworkError,
        onFlash: callbacks.onFlash,
        onPrefetched: callbacks.onPrefetched,
        onPrefetching: callbacks.onPrefetching,
      }),
    );
  });

  it('forwards duration-form prefetch options and prefetch lifecycle callbacks', () => {
    const onPrefetched = vi.fn();
    const onPrefetching = vi.fn();

    render(
      <ModalLink
        href="/users/1"
        prefetch="click"
        cacheFor={['250ms', '5s']}
        cacheTags="users"
        async
        viewTransition
        preserveErrors
        only={['user']}
        except={['audit']}
        reset={['users']}
        invalidateCacheTags="users"
        onPrefetched={onPrefetched}
        onPrefetching={onPrefetching}
      >
        Prefetch user
      </ModalLink>,
    );

    fireEvent.mouseDown(screen.getByRole('link', { name: 'Prefetch user' }));

    expect(mockPrefetchModal).toHaveBeenCalledWith(
      '/users/1',
      expect.objectContaining({
        method: 'get',
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ['user'],
        except: ['audit'],
        reset: ['users'],
        invalidateCacheTags: 'users',
        onPrefetched,
        onPrefetching,
        cacheFor: ['250ms', '5s'],
        cacheTags: 'users',
      }),
    );
  });
});
