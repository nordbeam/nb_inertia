import { mount } from "@vue/test-utils";
import { computed, defineComponent, h, nextTick, ref } from "vue";
import { beforeEach, describe, expect, it, vi } from "vite-plus/test";
import { MODAL_PAGE_KEY, type ModalPageObject } from "../modalPageContext";
import { usePage } from "../usePage";

const { mockOfficialUsePage } = vi.hoisted(() => ({
  mockOfficialUsePage: vi.fn(),
}));

vi.mock("@inertiajs/vue3", () => ({
  usePage: (...args: unknown[]) => mockOfficialUsePage(...args),
}));

describe("usePage (Vue)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockOfficialUsePage.mockReturnValue({
      component: "Dashboard",
      props: {},
      url: "/dashboard",
      version: null,
      rescuedProps: [],
    });
  });

  it("delegates to official usePage outside a modal", () => {
    const officialPage = { component: "Dashboard", props: { count: 1 } };
    mockOfficialUsePage.mockReturnValue(officialPage);

    let observed: unknown;
    const Probe = defineComponent({
      setup() {
        observed = usePage();
        return () => h("div");
      },
    });

    mount(Probe);

    expect(mockOfficialUsePage).toHaveBeenCalledTimes(1);
    expect(observed).toBe(officialPage);
  });

  it("exposes the complete v3 page metadata shape in a modal", async () => {
    const state = ref<ModalPageObject | null>({
      component: "ModalPage",
      props: { count: 1 },
      url: "/modal",
      version: "v1",
      clearHistory: true,
      preserveFragment: true,
      encryptHistory: true,
      deferredProps: { stats: ["stats"] },
      initialDeferredProps: { stats: ["stats"] },
      rescuedProps: ["stats"],
      mergeProps: ["items"],
      prependProps: ["messages"],
      deepMergeProps: ["profile"],
      matchPropsOn: ["id"],
      sharedProps: ["auth"],
      scrollProps: {},
      flash: { notice: "Saved" },
      onceProps: { account: { prop: "account", expiresAt: null } },
      optimisticUpdatedAt: { count: 123 },
      scrollRegions: [{ top: 10, left: 20 }],
      rememberedState: { tab: "details" },
    });

    let observed: ReturnType<typeof usePage> | undefined;
    const Probe = defineComponent({
      setup() {
        observed = usePage();
        return () => h("div");
      },
    });

    mount(Probe, {
      global: {
        provide: {
          [MODAL_PAGE_KEY as symbol]: computed(() => state.value),
        },
      },
    });

    expect(mockOfficialUsePage).not.toHaveBeenCalled();
    expect(observed?.component).toBe("ModalPage");
    expect(observed?.deferredProps).toEqual({ stats: ["stats"] });
    expect(observed?.initialDeferredProps).toEqual({ stats: ["stats"] });
    expect(observed?.rescuedProps).toEqual(["stats"]);
    expect(observed?.mergeProps).toEqual(["items"]);
    expect(observed?.prependProps).toEqual(["messages"]);
    expect(observed?.deepMergeProps).toEqual(["profile"]);
    expect(observed?.matchPropsOn).toEqual(["id"]);
    expect(observed?.sharedProps).toEqual(["auth"]);
    expect(observed?.onceProps).toEqual({ account: { prop: "account", expiresAt: null } });
    expect(observed?.optimisticUpdatedAt).toEqual({ count: 123 });

    state.value = {
      ...state.value!,
      rescuedProps: ["next"],
      deferredProps: undefined,
    };
    await nextTick();

    expect(observed?.rescuedProps).toEqual(["next"]);
    expect(observed?.deferredProps).toBeUndefined();
  });
});
