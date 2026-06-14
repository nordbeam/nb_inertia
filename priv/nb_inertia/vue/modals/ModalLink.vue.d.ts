import type { DefineComponent } from 'vue';
import type { ModalConfig } from './types';
import type { RouteResult } from '../../shared/types';

type PrefetchMode = 'hover' | 'mount' | 'click';

export interface ModalLinkProps {
  href: string | RouteResult;
  modalConfig?: ModalConfig;
  baseUrl?: string;
  method?: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';
  data?: Record<string, unknown>;
  class?: string;
  prefetch?: boolean | PrefetchMode | PrefetchMode[];
  cacheFor?: number;
  cacheTags?: string[];
}

declare const ModalLink: DefineComponent<ModalLinkProps, Record<string, never>, unknown>;
export default ModalLink;
