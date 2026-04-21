import { router as inertiaRouter } from '@inertiajs/react';
import { getCurrentModalRequestContext, mergeModalHeaders } from './modals/requestContext';

function withCurrentModalHeaders<TOptions extends { headers?: Record<string, string> } | undefined>(
  options: TOptions
): TOptions {
  return mergeModalHeaders(options, getCurrentModalRequestContext());
}

export const router = {
  ...inertiaRouter,
  visit(url: Parameters<typeof inertiaRouter.visit>[0], options?: Parameters<typeof inertiaRouter.visit>[1]) {
    return inertiaRouter.visit(url, withCurrentModalHeaders(options));
  },
  get(
    url: Parameters<typeof inertiaRouter.get>[0],
    data?: Parameters<typeof inertiaRouter.get>[1],
    options?: Parameters<typeof inertiaRouter.get>[2]
  ) {
    return inertiaRouter.get(url, data, withCurrentModalHeaders(options));
  },
  post(
    url: Parameters<typeof inertiaRouter.post>[0],
    data?: Parameters<typeof inertiaRouter.post>[1],
    options?: Parameters<typeof inertiaRouter.post>[2]
  ) {
    return inertiaRouter.post(url, data, withCurrentModalHeaders(options));
  },
  put(
    url: Parameters<typeof inertiaRouter.put>[0],
    data?: Parameters<typeof inertiaRouter.put>[1],
    options?: Parameters<typeof inertiaRouter.put>[2]
  ) {
    return inertiaRouter.put(url, data, withCurrentModalHeaders(options));
  },
  patch(
    url: Parameters<typeof inertiaRouter.patch>[0],
    data?: Parameters<typeof inertiaRouter.patch>[1],
    options?: Parameters<typeof inertiaRouter.patch>[2]
  ) {
    return inertiaRouter.patch(url, data, withCurrentModalHeaders(options));
  },
  delete(
    url: Parameters<typeof inertiaRouter.delete>[0],
    options?: Parameters<typeof inertiaRouter.delete>[1]
  ) {
    return inertiaRouter.delete(url, withCurrentModalHeaders(options));
  },
  reload(options?: Parameters<typeof inertiaRouter.reload>[0]) {
    return inertiaRouter.reload(withCurrentModalHeaders(options));
  },
};

export default router;
