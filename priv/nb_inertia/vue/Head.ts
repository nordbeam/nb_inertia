import { Head as InertiaHead } from '@inertiajs/vue3';
import { defineComponent, h, type PropType, type VNodeChild } from 'vue';
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

    return () => {
      // Keep modal head entries isolated from the page's metadata while still
      // using Inertia's provider. This preserves the configured title callback
      // (including its page argument) and lets the provider restore the parent
      // head when the modal closes.
      const slot = isInModal.value ? undefined : slots.default;
      return h(
        InertiaHead,
        { title: props.title },
        slot ? { default: () => slot() as VNodeChild[] } : undefined,
      );
    };
  },
});
