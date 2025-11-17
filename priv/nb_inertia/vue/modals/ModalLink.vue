<template>
  <a
    :href="finalHref"
    :class="linkClassName"
    @click="handleClick"
  >
    <slot />
  </a>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { router } from '../router';
import { useModalStack } from './modalStack';
import type { ModalConfig } from './types';
import type { RouteResult } from '../router';

/**
 * ModalLink - Link component that opens Inertia pages in modals (Vue)
 *
 * When clicked, this component fetches the target page and displays it in a modal
 * instead of navigating to it. Integrates with the modal stack and supports
 * RouteResult objects from nb_routes.
 *
 * @example
 * ```vue
 * <template>
 *   <ModalLink :href="user_path(1)" :modal-config="{ size: 'lg' }">
 *     View User
 *   </ModalLink>
 * </template>
 *
 * <script setup>
 * import { ModalLink } from '@/modals';
 * import { user_path } from '@/routes';
 * </script>
 * ```
 */

interface Props {
  /**
   * The URL or RouteResult to navigate to
   */
  href: string | RouteResult;

  /**
   * Optional modal configuration
   */
  modalConfig?: ModalConfig;

  /**
   * Base URL for the modal
   */
  baseUrl?: string;

  /**
   * HTTP method to use for the request
   */
  method?: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head';

  /**
   * Data to send with the request (for POST/PUT/PATCH/DELETE)
   */
  data?: Record<string, any>;

  /**
   * Additional CSS classes
   */
  class?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modalConfig: () => ({}),
  method: 'get',
});

const { pushModal } = useModalStack();
const isLoading = ref(false);

/**
 * Type guard to check if a value is a RouteResult object
 */
function isRouteResult(value: unknown): value is RouteResult {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const obj = value as Record<string, unknown>;

  return (
    typeof obj.url === 'string' &&
    typeof obj.method === 'string' &&
    ['get', 'post', 'put', 'patch', 'delete', 'head'].includes(obj.method)
  );
}

// Extract URL and method from RouteResult if provided
const finalHref = computed(() => {
  return isRouteResult(props.href) ? props.href.url : props.href;
});

const finalMethod = computed(() => {
  return (isRouteResult(props.href) && !props.method ? props.href.method : props.method) || 'get';
});

const linkClassName = computed(() => {
  const classes = [props.class];
  if (isLoading.value) {
    classes.push('opacity-50 cursor-wait');
  } else {
    classes.push('cursor-pointer');
  }
  return classes.filter(Boolean).join(' ');
});

function handleClick(e: MouseEvent) {
  // Allow modifier keys to work normally (open in new tab, etc.)
  if (e.ctrlKey || e.metaKey || e.shiftKey) {
    return;
  }

  e.preventDefault();

  isLoading.value = true;

  // Use Inertia router to fetch the modal page
  router.visit(finalHref.value, {
    method: finalMethod.value,
    data: props.data,
    preserveState: true,
    preserveScroll: true,
    only: [],
    onSuccess: (page) => {
      // Extract modal data from response
      const component = page.component;
      const componentProps = page.props;

      // Push modal to stack
      pushModal({
        component: component as any,
        props: componentProps,
        config: props.modalConfig,
        baseUrl: props.baseUrl || window.location.pathname,
      });

      isLoading.value = false;
    },
    onError: () => {
      isLoading.value = false;
    },
    onFinish: () => {
      isLoading.value = false;
    },
  });
}
</script>
