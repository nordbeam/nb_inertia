import { mount } from "@vue/test-utils";
import { describe, expect, it, vi, beforeEach } from "vite-plus/test";
import ModalLink from "../modals/ModalLink.vue";
import { MODAL_STACK_KEY, createModalStack } from "../modals/modalStack";

const { mockVisit, mockPrefetch } = vi.hoisted(() => ({
  mockVisit: vi.fn(),
  mockPrefetch: vi.fn(),
}));

vi.mock("@inertiajs/vue3", () => ({
  router: {
    visit: mockVisit,
    prefetch: mockPrefetch,
  },
}));

function mountLink(props: Record<string, unknown>) {
  return mount(ModalLink, {
    props: {
      href: "/modal",
      ...props,
    },
    global: {
      provide: {
        [MODAL_STACK_KEY as symbol]: createModalStack(),
      },
    },
  });
}

describe("ModalLink (Vue)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("uses the RouteResult method when no explicit method is provided", async () => {
    const wrapper = mountLink({
      href: { url: "/posts/1", method: "patch" },
    });

    await wrapper.get("a").trigger("click");

    expect(mockVisit).toHaveBeenCalledWith(
      "/posts/1",
      expect.objectContaining({ method: "patch" }),
    );
  });

  it("allows an explicit method to override a RouteResult method", async () => {
    const wrapper = mountLink({
      href: { url: "/posts/1", method: "patch" },
      method: "post",
    });

    await wrapper.get("a").trigger("click");

    expect(mockVisit).toHaveBeenCalledWith("/posts/1", expect.objectContaining({ method: "post" }));
  });

  it.each([
    ["a different browsing target", { target: "_blank" }, {}],
    ["Alt-click", {}, { altKey: true }],
    ["Ctrl-click", {}, { ctrlKey: true }],
    ["Cmd-click", {}, { metaKey: true }],
    ["Shift-click", {}, { shiftKey: true }],
    ["a middle click", {}, { button: 1 }],
  ])("does not intercept %s", async (_description, props, event) => {
    const wrapper = mountLink(props);

    await wrapper.get("a").trigger("click", event);

    expect(mockVisit).not.toHaveBeenCalled();
  });

  it("preserves standard anchor attributes", () => {
    const wrapper = mountLink({ target: "_blank", rel: "noopener", download: true });

    expect(wrapper.get("a").attributes()).toMatchObject({
      target: "_blank",
      rel: "noopener",
      download: "true",
    });
  });

  it("does not intercept an event that was already prevented", async () => {
    const wrapper = mountLink({});
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });
    event.preventDefault();

    wrapper.get("a").element.dispatchEvent(event);

    expect(mockVisit).not.toHaveBeenCalled();
  });
});
