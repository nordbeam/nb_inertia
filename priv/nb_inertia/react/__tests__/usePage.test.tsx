import React from 'react';
import { renderHook } from '@testing-library/react';
import { describe, expect, it } from 'vite-plus/test';
import { usePage } from '../usePage';
import { ModalPageProvider } from '../modals';

const pageMetadata = {
  version: 'v3',
  deferredProps: { users: ['users'] },
  initialDeferredProps: { users: ['users'] },
  rescuedProps: ['users'],
  mergeProps: ['users'],
  prependProps: ['notifications'],
  deepMergeProps: ['profile'],
  matchPropsOn: ['users.id'],
  sharedProps: ['auth'],
  onceProps: { account: { prop: 'account' } },
  optimisticUpdatedAt: { account: 123 },
};

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <ModalPageProvider
      component="Users/Index"
      props={{ users: [] }}
      url="/users"
      pageMetadata={pageMetadata}
    >
      {children}
    </ModalPageProvider>
  );
}

describe('modal page metadata', () => {
  it('exposes all official v3 page metadata through the enhanced hook', () => {
    const { result } = renderHook(() => usePage(), { wrapper });

    expect(result.current).toMatchObject({
      component: 'Users/Index',
      url: '/users',
      version: 'v3',
      rescuedProps: ['users'],
      deferredProps: { users: ['users'] },
      initialDeferredProps: { users: ['users'] },
      mergeProps: ['users'],
      prependProps: ['notifications'],
      deepMergeProps: ['profile'],
      matchPropsOn: ['users.id'],
      sharedProps: ['auth'],
      onceProps: { account: { prop: 'account' } },
      optimisticUpdatedAt: { account: 123 },
    });
  });

  it('defaults rescuedProps for older modal payloads', () => {
    const { result } = renderHook(() => usePage(), {
      wrapper: ({ children }) => (
        <ModalPageProvider component="Users/Index" props={{}} url="/users">
          {children}
        </ModalPageProvider>
      ),
    });

    expect(result.current.rescuedProps).toEqual([]);
  });
});
