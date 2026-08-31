import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { beforeEach, describe, expect, it, vi } from "vite-plus/test";
import HeadlessModal from "../modals/HeadlessModal.vue";
import { MODAL_STACK_KEY, createModalStack } from "../modals/modalStack";

const { mockVisit } = vi.hoisted(() => ({
  mockVisit: vi.fn(),
}));

vi.mock("@inertiajs/vue3", () => ({
  router: {
    visit: mockVisit,
  },
}));

const Content = defineComponent({
  name: "Content",
  setup() {
    return () => h("div");
  },
});

function mountModal(props: Record<string, unknown> = {}) {
  return mount(HeadlessModal, {
    props: {
      component: Content,
      baseUrl: "/dashboard",
      ...props,
    },
    global: {
      provide: {
        [MODAL_STACK_KEY as symbol]: createModalStack(),
      },
    },
    slots: {
      default: ({
        modal,
      }: {
        modal: { page?: { rescuedProps?: string[]; version?: string | null } };
      }) =>
        h("div", {
          "data-rescued": modal.page?.rescuedProps?.join(",") ?? "",
          "data-version": modal.page?.version ?? "",
        }),
    },
  });
}

describe("HeadlessModal (Vue)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("carries supplied v3 page metadata into the modal context", () => {
    const wrapper = mountModal({
      page: {
        component: "ModalPage",
        props: { count: 1 },
        url: "/modal",
        version: "v3",
        rescuedProps: ["stats"],
        deferredProps: { stats: ["stats"] },
        onceProps: { account: { prop: "account", expiresAt: null } },
      },
    });

    expect(wrapper.get("[data-rescued]").attributes("data-rescued")).toBe("stats");
    expect(wrapper.get("[data-version]").attributes("data-version")).toBe("v3");
  });

  it("defaults rescuedProps and other page metadata for manually-created modals", () => {
    const wrapper = mountModal();

    expect(wrapper.get("[data-rescued]").attributes("data-rescued")).toBe("");
    expect(wrapper.get("[data-version]").attributes("data-version")).toBe("");
  });
});
