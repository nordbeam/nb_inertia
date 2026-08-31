import type { DefineComponent } from 'vue';
import type { CacheForOption, Method, RequestPayload, VisitOptions } from '@inertiajs/core';
import type { ModalConfig } from './types';
import type { RouteResult } from '../../shared/types';

type PrefetchMode = 'hover' | 'mount' | 'click';

export interface ModalLinkProps {
  href: string | RouteResult;
  modalConfig?: ModalConfig;
  baseUrl?: string;
  method?: Method;
  data?: RequestPayload;
  component?: VisitOptions['component'];
  replace?: VisitOptions['replace'];
  preserveScroll?: VisitOptions['preserveScroll'];
  preserveState?: VisitOptions['preserveState'];
  preserveUrl?: VisitOptions['preserveUrl'];
  only?: VisitOptions['only'];
  except?: VisitOptions['except'];
  headers?: VisitOptions['headers'];
  errorBag?: VisitOptions['errorBag'];
  forceFormData?: VisitOptions['forceFormData'];
  queryStringArrayFormat?: VisitOptions['queryStringArrayFormat'];
  async?: VisitOptions['async'];
  showProgress?: VisitOptions['showProgress'];
  fresh?: VisitOptions['fresh'];
  reset?: VisitOptions['reset'];
  preserveErrors?: VisitOptions['preserveErrors'];
  invalidateCacheTags?: VisitOptions['invalidateCacheTags'];
  viewTransition?: VisitOptions['viewTransition'];
  optimistic?: VisitOptions['optimistic'];
  pageProps?: VisitOptions['pageProps'];
  onCancelToken?: VisitOptions['onCancelToken'];
  onBefore?: VisitOptions['onBefore'];
  onBeforeUpdate?: VisitOptions['onBeforeUpdate'];
  onStart?: VisitOptions['onStart'];
  onProgress?: VisitOptions['onProgress'];
  onFinish?: VisitOptions['onFinish'];
  onCancel?: VisitOptions['onCancel'];
  onSuccess?: VisitOptions['onSuccess'];
  onError?: VisitOptions['onError'];
  onHttpException?: VisitOptions['onHttpException'];
  onNetworkError?: VisitOptions['onNetworkError'];
  onFlash?: VisitOptions['onFlash'];
  onPrefetched?: VisitOptions['onPrefetched'];
  onPrefetching?: VisitOptions['onPrefetching'];
  class?: string;
  prefetch?: boolean | PrefetchMode | PrefetchMode[];
  cacheFor?: CacheForOption | CacheForOption[];
  cacheTags?: string | string[];
  returnUrl?: string;
  target?: string;
  rel?: string;
  download?: string | boolean;
}

declare const ModalLink: DefineComponent<ModalLinkProps, Record<string, never>, unknown>;
export default ModalLink;
