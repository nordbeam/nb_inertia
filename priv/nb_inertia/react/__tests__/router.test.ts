import { afterEach, describe, expect, it, vi } from 'vite-plus/test';
import { router as nativeRouter } from '@inertiajs/react';
import { router } from '../router';
import {
  registerModalRequestContext,
  unregisterModalRequestContext,
} from '../modals/requestContext';

const modalContextId = Symbol('router-test-modal-context');

describe('enhanced React router', () => {
  afterEach(() => {
    unregisterModalRequestContext(modalContextId);
    vi.restoreAllMocks();
  });

  it('preserves the complete native Router prototype and fluent API', () => {
    const nativeMethods = [
      'init',
      'optimistic',
      'on',
      'once',
      'cancelAll',
      'poll',
      'getCached',
      'flush',
      'flushAll',
      'flushByCacheTags',
      'getPrefetching',
      'prefetch',
      'clearHistory',
      'decryptHistory',
      'resolveComponent',
      'replace',
      'replaceProp',
      'appendToProp',
      'prependToProp',
      'push',
      'flash',
      'visit',
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'reload',
    ];

    for (const method of nativeMethods) {
      expect(typeof (router as unknown as Record<string, unknown>)[method]).toBe('function');
    }

    expect(Object.getPrototypeOf(router)).toBe(Object.getPrototypeOf(nativeRouter));
    expect(router.optimistic(() => undefined)).toBe(router);
  });

  it('merges modal headers into visits, polling, prefetch, and cache lookups', () => {
    registerModalRequestContext(modalContextId, {
      url: '/users/1/edit',
      returnUrl: '/users?page=2',
    });

    const visit = vi.spyOn(nativeRouter, 'visit').mockImplementation(() => undefined);
    const poll = vi.spyOn(nativeRouter, 'poll').mockImplementation(() => ({
      stop: vi.fn(),
      start: vi.fn(),
      destroy: vi.fn(),
    }));
    const prefetch = vi.spyOn(nativeRouter, 'prefetch').mockImplementation(() => undefined);
    const getCached = vi.spyOn(nativeRouter, 'getCached').mockReturnValue(null);
    const flush = vi.spyOn(nativeRouter, 'flush').mockImplementation(() => undefined);
    const getPrefetching = vi.spyOn(nativeRouter, 'getPrefetching').mockReturnValue(null);

    router.visit('/users/1/edit', { headers: { 'x-custom': 'yes' } });
    expect(visit).toHaveBeenCalledWith('/users/1/edit', {
      headers: {
        'x-custom': 'yes',
        'x-inertia-modal': 'true',
        'x-inertia-modal-base-url': '/users?page=2',
      },
    });

    router.optimistic(() => undefined).visit('/users/1/edit');
    expect(visit).toHaveBeenLastCalledWith('/users/1/edit', {
      headers: {
        'x-inertia-modal': 'true',
        'x-inertia-modal-base-url': '/users?page=2',
      },
    });

    const requestOptions = vi.fn(() => ({ only: ['permissions'] }));
    router.poll(1000, requestOptions);
    const wrappedRequestOptions = poll.mock.calls[0]?.[1];
    expect(typeof wrappedRequestOptions).toBe('function');
    expect((wrappedRequestOptions as () => Record<string, unknown>)()).toEqual({
      only: ['permissions'],
      headers: {
        'x-inertia-modal': 'true',
        'x-inertia-modal-base-url': '/users?page=2',
      },
    });
    expect(requestOptions).toHaveBeenCalledTimes(1);

    const options = { headers: { 'x-custom': 'yes' } };
    router.prefetch('/users/1/edit', options, { cacheFor: 30_000 });
    router.getCached('/users/1/edit', options);
    router.flush('/users/1/edit', options);
    router.getPrefetching('/users/1/edit', options);

    const expectedHeaders = {
      'x-custom': 'yes',
      'x-inertia-modal': 'true',
      'x-inertia-modal-base-url': '/users?page=2',
    };
    expect(prefetch.mock.calls[0]?.[1]).toEqual({ headers: expectedHeaders });
    expect(getCached.mock.calls[0]?.[1]).toEqual({ headers: expectedHeaders });
    expect(flush.mock.calls[0]?.[1]).toEqual({ headers: expectedHeaders });
    expect(getPrefetching.mock.calls[0]?.[1]).toEqual({ headers: expectedHeaders });
  });
});
