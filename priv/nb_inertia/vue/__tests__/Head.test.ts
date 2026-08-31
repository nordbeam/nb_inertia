import { mount } from "@vue/test-utils";
import { nextTick, computed, h, ref } from "vue";
import { describe, expect, it, vi } from "vite-plus/test";
import Head from "../Head";
import { MODAL_PAGE_KEY } from "../modalPageContext";

const { OfficialHead } = vi.hoisted(() => ({
  OfficialHead: {
    name: "OfficialHead",
    props: {
      title: {
        type: String,
        required: false,
      },
    },
    setup(_props: unknown, { slots }: { slots: { default?: () => unknown } }) {
      return () => slots.default?.() ?? null;
    },
  },
}));

vi.mock("@inertiajs/vue3", () => ({ Head: OfficialHead }));

describe("Head (Vue)", () => {
  it("delegates title and metadata slots to official Inertia Head", () => {
    const wrapper = mount(Head, {
      props: { title: "Dashboard" },
      slots: {
        default: () => h("meta", { "data-test": "page-head", name: "description" }),
      },
    });

    const officialHead = wrapper.findComponent(OfficialHead);

    expect(officialHead.exists()).toBe(true);
    expect(officialHead.props("title")).toBe("Dashboard");
    expect(wrapper.find('[data-test="page-head"]').exists()).toBe(true);
  });

  it("keeps the official head provider active in modals while isolating metadata slots", async () => {
    const inModal = ref(false);
    const modalPage = computed(() =>
      inModal.value
        ? {
            component: "ModalPage",
            props: {},
            url: "/modal",
            version: null,
            rescuedProps: [],
          }
        : null,
    );

    const wrapper = mount(Head, {
      props: { title: "Modal title" },
      slots: {
        default: () => h("meta", { "data-test": "page-head", name: "description" }),
      },
      global: {
        provide: {
          [MODAL_PAGE_KEY as symbol]: modalPage,
        },
      },
    });

    inModal.value = true;
    await nextTick();

    expect(wrapper.findComponent(OfficialHead).exists()).toBe(true);
    expect(wrapper.findComponent(OfficialHead).props("title")).toBe("Modal title");
    expect(wrapper.find('[data-test="page-head"]').exists()).toBe(false);

    inModal.value = false;
    await nextTick();

    expect(wrapper.find('[data-test="page-head"]').exists()).toBe(true);
  });
});
