<script setup lang="ts">
/**
 * NbInertia Enhanced Link Component for Vue
 *
 * Provides an enhanced Inertia.js Link component that accepts both string URLs
 * and RouteResult objects from nb_routes rich mode. Maintains full backward
 * compatibility with standard Inertia Link usage.
 *
 * @example
 * import Link from '@/nb_inertia/Link.vue';
 * import { post_path, update_post_path } from '@/routes';
 *
 * // Use with RouteResult objects
 * <Link :href="post_path(1)">View Post</Link>
 * <Link :href="update_post_path.patch(1)">Edit Post</Link>
 *
 * // Still works with plain strings
 * <Link href="/posts/1">View Post</Link>
 * <Link href="/posts/1" method="post">Create</Link>
 */

import { computed } from 'vue';
import { Link as InertiaLink } from '@inertiajs/vue3';
import type { RouteResult } from './router';
import type { Method } from '@inertiajs/core';

/**
 * Enhanced Link props that accept RouteResult objects
 *
 * Extends the standard Inertia Link props to accept RouteResult objects
 * in the href prop, while maintaining backward compatibility with strings.
 */
export interface LinkProps {
  /**
   * The URL or RouteResult to navigate to
   *
   * Can be a plain string URL or a RouteResult object from nb_routes rich mode.
   * When a RouteResult is provided, the URL and method are automatically extracted.
   *
   * @example
   * // String URL
   * <Link href="/posts/1">View</Link>
   *
   * // RouteResult object
   * <Link :href="post_path(1)">View</Link>
   * <Link :href="update_post_path.patch(1)">Edit</Link>
   */
  href: string | RouteResult;

  /**
   * HTTP method to use for the request
   *
   * When using a RouteResult, this will override the method from the route.
   * When using a string URL, this specifies the method to use.
   */
  method?: Method;

  /**
   * Data to send with the request
   */
  data?: Record<string, unknown>;

  /**
   * Replace current history state instead of pushing
   */
  replace?: boolean;

  /**
   * Preserve scroll position after navigation
   */
  preserveScroll?: boolean | ((props: { [key: string]: unknown }) => boolean);

  /**
   * Preserve component state after navigation
   */
  preserveState?: boolean | ((props: { [key: string]: unknown }) => boolean) | null;

  /**
   * Only load specific props on navigation
   */
  only?: string[];

  /**
   * Except specific props from loading
   */
  except?: string[];

  /**
   * Custom headers to send with the request
   */
  headers?: Record<string, string>;

  /**
   * Name of the error bag to use
   */
  queryStringArrayFormat?: 'indices' | 'brackets';

  /**
   * Render the link as a different element or component
   */
  as?: string;

  /**
   * Prefix to use for external URLs
   */
  prefetch?: boolean | string[];
}

const props = withDefaults(defineProps<LinkProps>(), {
  method: undefined,
  data: undefined,
  replace: false,
  preserveScroll: false,
  preserveState: null,
  only: undefined,
  except: undefined,
  headers: undefined,
  queryStringArrayFormat: 'brackets',
  as: 'a',
  prefetch: false,
});

/**
 * Type guard to check if a value is a RouteResult object
 *
 * @param value - Value to check
 * @returns true if value is a RouteResult object
 */
function isRouteResult(value: unknown): value is RouteResult {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const obj = value as Record<string, unknown>;

  return (
    typeof obj.url === 'string' &&
    typeof obj.method === 'string' &&
    ['get', 'post', 'put', 'patch', 'delete', 'head'].includes(obj.method as string)
  );
}

/**
 * Computed href - extracts URL from RouteResult or uses string directly
 */
const finalHref = computed(() => {
  return isRouteResult(props.href) ? props.href.url : props.href;
});

/**
 * Computed method - extracts method from RouteResult if available, otherwise uses explicit method
 */
const finalMethod = computed(() => {
  if (isRouteResult(props.href) && !props.method) {
    return props.href.method as Method;
  }
  return props.method;
});
</script>

<template>
  <InertiaLink
    :href="finalHref"
    :method="finalMethod"
    :data="data"
    :replace="replace"
    :preserve-scroll="preserveScroll"
    :preserve-state="preserveState"
    :only="only"
    :except="except"
    :headers="headers"
    :query-string-array-format="queryStringArrayFormat"
    :as="as"
    :prefetch="prefetch"
  >
    <slot />
  </InertiaLink>
</template>
