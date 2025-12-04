<template>
  <a
    :href="finalHref"
    :class="linkClassName"
    @click="handleClick"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    @mousedown="handleMouseDown"
  >
    <slot />
  </a>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { router } from '@inertiajs/vue3';
import { useModalStack } from './modalStack';
import type { ModalConfig } from './types';
import type { RouteResult } from '../../shared/types';
import { isRouteResult } from '../../shared/types';

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

type PrefetchMode = 'hover' | 'mount' | 'click';

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

  /**
   * Enable prefetching. Can be:
   * - boolean: true enables hover prefetch
   * - 'hover' | 'mount' | 'click': single mode
   * - ('hover' | 'mount' | 'click')[]: multiple modes
   *
   * Note: Prefetching only works for GET requests.
   */
  prefetch?: boolean | PrefetchMode | PrefetchMode[];

  /**
   * Duration in milliseconds to cache prefetched data
   *
   * @default 30000 (30 seconds)
   */
  cacheFor?: number;

  /**
   * Tags for organizing cached prefetch data
   */
  cacheTags?: string[];
}

const props = withDefaults(defineProps<Props>(), {
  modalConfig: () => ({}),
  method: 'get',
  prefetch: false,
});

const { pushModal } = useModalStack();
const isLoading = ref(false);

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

// Normalize prefetch prop to array of modes
const prefetchModes = computed((): PrefetchMode[] => {
  if (!props.prefetch) return [];
  if (props.prefetch === true) return ['hover'];
  if (typeof props.prefetch === 'string') return [props.prefetch];
  return props.prefetch;
});

// Prefetch function - only GET requests can be prefetched
function doPrefetch() {
  if (finalMethod.value !== 'get') return;
  (router as any).prefetch?.(finalHref.value, { preserveState: true }, {
    cacheFor: props.cacheFor,
    cacheTags: props.cacheTags,
  });
}

// Hover prefetch with delay
let hoverTimeout: ReturnType<typeof setTimeout> | null = null;

function handleMouseEnter() {
  if (prefetchModes.value.includes('hover')) {
    hoverTimeout = setTimeout(doPrefetch, 75);
  }
}

function handleMouseLeave() {
  if (hoverTimeout) {
    clearTimeout(hoverTimeout);
    hoverTimeout = null;
  }
}

// Click prefetch (mousedown)
function handleMouseDown() {
  if (prefetchModes.value.includes('click')) {
    doPrefetch();
  }
}

// Mount prefetch
onMounted(() => {
  if (prefetchModes.value.includes('mount')) {
    setTimeout(doPrefetch, 0);
  }
});

// Cleanup hover timeout on unmount
onUnmounted(() => {
  if (hoverTimeout) {
    clearTimeout(hoverTimeout);
  }
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
