import { Head as InertiaHead } from '@inertiajs/vue3';
import {
  defineComponent,
  h,
  onBeforeUnmount,
  watch,
  type PropType,
  type VNodeChild,
} from 'vue';
import { useIsInModal } from './modalPageContext';

export default defineComponent({
  name: 'NbInertiaHead',
  props: {
    title: {
      type: String as PropType<string | undefined>,
      required: false,
    },
  },
  setup(props, { slots }) {
    const isInModal = useIsInModal();
    let originalTitle: string | null = null;

    watch(
      [isInModal, () => props.title],
      ([inModal, title]) => {
        if (!inModal || !title || typeof document === 'undefined') {
          return;
        }

        if (originalTitle === null) {
          originalTitle = document.title;
        }

        document.title = title;
      },
      { immediate: true }
    );

    onBeforeUnmount(() => {
      if (originalTitle !== null && typeof document !== 'undefined') {
        document.title = originalTitle;
      }
    });

    return () => {
      if (isInModal.value) {
        return null;
      }

      return h(
        InertiaHead,
        { title: props.title },
        slots.default ? { default: () => slots.default() as VNodeChild[] } : undefined
      );
    };
  },
});
