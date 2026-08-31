import { router as inertiaRouter } from '@inertiajs/react';
import type { ReloadOptions, VisitOptions } from '@inertiajs/core';
import { getCurrentModalRequestContext, mergeModalHeaders } from './modals/requestContext';

type HeaderOptions = Pick<VisitOptions, 'headers'> | undefined;

function withCurrentModalHeaders<TOptions extends HeaderOptions>(options: TOptions): TOptions {
  return mergeModalHeaders(options, getCurrentModalRequestContext());
}

function withCurrentModalHeadersResolver(
  requestOptions?: ReloadOptions | (() => ReloadOptions),
): ReloadOptions | (() => ReloadOptions) | undefined {
  if (typeof requestOptions === 'function') {
    return () => withCurrentModalHeaders(requestOptions());
  }

  return withCurrentModalHeaders(requestOptions);
}

function withHeadersAt<TArgs extends unknown[]>(args: TArgs, index: number): TArgs {
  const nextArgs = [...args] as TArgs;
  nextArgs[index] = withCurrentModalHeaders(nextArgs[index] as HeaderOptions) as TArgs[number];
  return nextArgs;
}

/**
 * Keep the native Router instance as the target so prototype methods, getters,
 * own state, and `instanceof Router` all continue to work. Every function is
 * invoked with the native instance as `this`; only request options are
 * adjusted for the active modal context.
 */
export const router = new Proxy(inertiaRouter, {
  get(target, property, receiver) {
    const value = Reflect.get(target, property, target);

    if (typeof value !== 'function') {
      return value;
    }

    return (...args: unknown[]) => {
      let nextArgs = args;

      switch (property) {
        case 'visit':
        case 'reload':
          nextArgs = withHeadersAt(nextArgs, property === 'visit' ? 1 : 0);
          break;
        case 'get':
        case 'post':
        case 'put':
        case 'patch':
          nextArgs = withHeadersAt(nextArgs, 2);
          break;
        case 'delete':
          nextArgs = withHeadersAt(nextArgs, 1);
          break;
        case 'poll':
          nextArgs = [...nextArgs];
          nextArgs[1] = withCurrentModalHeadersResolver(
            nextArgs[1] as ReloadOptions | (() => ReloadOptions) | undefined,
          );
          break;
        case 'prefetch':
        case 'getCached':
        case 'flush':
        case 'getPrefetching':
          nextArgs = withHeadersAt(nextArgs, 1);
          break;
      }

      const result = Reflect.apply(value, target, nextArgs);

      // Native `optimistic()` returns `this`; keep fluent chains on the proxy
      // so the next request still receives modal headers.
      return result === target ? receiver : result;
    };
  },
}) as typeof inertiaRouter;

export default router;
