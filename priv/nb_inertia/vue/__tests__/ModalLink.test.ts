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

function mountLink(props: Record<string, unknown>, stack = createModalStack()) {
  return mount(ModalLink, {
    props: {
      href: "/modal",
      ...props,
    },
    global: {
      provide: {
        [MODAL_STACK_KEY as symbol]: stack,
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

    expect(mockVisit).toHaveBeenCalledWith(
      "/posts/1",
      expect.objectContaining({ method: "post" }),
    );
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
    const wrapper = mountLink({
      target: "_blank",
      rel: "noopener",
      download: true,
    });

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

  it("forwards the complete Inertia 3.7 visit option surface", async () => {
    const callbacks = {
      onBefore: vi.fn(),
      onBeforeUpdate: vi.fn(),
      onStart: vi.fn(),
      onProgress: vi.fn(),
      onFinish: vi.fn(),
      onCancel: vi.fn(),
      onSuccess: vi.fn(),
      onError: vi.fn(),
      onHttpException: vi.fn(),
      onNetworkError: vi.fn(),
      onFlash: vi.fn(),
      onPrefetched: vi.fn(),
      onPrefetching: vi.fn(),
    };
    const wrapper = mountLink({
      async: true,
      viewTransition: true,
      preserveErrors: true,
      only: ["user"],
      except: ["audit"],
      reset: ["users"],
      invalidateCacheTags: ["users"],
      fresh: true,
      preserveUrl: true,
      ...callbacks,
    });

    await wrapper.get("a").trigger("click");

    expect(mockVisit).toHaveBeenCalledWith(
      "/modal",
      expect.objectContaining({
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ["user"],
        except: ["audit"],
        reset: ["users"],
        invalidateCacheTags: ["users"],
        fresh: true,
        preserveUrl: true,
        onBefore: callbacks.onBefore,
        onBeforeUpdate: callbacks.onBeforeUpdate,
        onStart: callbacks.onStart,
        onProgress: callbacks.onProgress,
        onFinish: expect.any(Function),
        onCancel: callbacks.onCancel,
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
        onHttpException: callbacks.onHttpException,
        onNetworkError: callbacks.onNetworkError,
        onFlash: callbacks.onFlash,
        onPrefetched: callbacks.onPrefetched,
        onPrefetching: callbacks.onPrefetching,
      }),
    );
  });

  it("forwards duration-form cache options and visit options to prefetch", async () => {
    const onPrefetched = vi.fn();
    const onPrefetching = vi.fn();
    const wrapper = mountLink({
      prefetch: "hover",
      cacheFor: ["250ms", "5s"],
      cacheTags: "users",
      async: true,
      viewTransition: true,
      preserveErrors: true,
      only: ["user"],
      except: ["audit"],
      reset: ["users"],
      invalidateCacheTags: "users",
      onPrefetched,
      onPrefetching,
    });

    await wrapper.get("a").trigger("mouseenter");
    await new Promise((resolve) => setTimeout(resolve, 100));

    expect(mockPrefetch).toHaveBeenCalledWith(
      "/modal",
      expect.objectContaining({
        method: "get",
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ["user"],
        except: ["audit"],
        reset: ["users"],
        invalidateCacheTags: "users",
        onPrefetched,
        onPrefetching,
      }),
      { cacheFor: ["250ms", "5s"], cacheTags: "users" },
    );
  });

  it("does not pass undefined cache options to Inertia prefetch", async () => {
    const wrapper = mountLink({ prefetch: "hover" });

    await wrapper.get("a").trigger("mouseenter");
    await new Promise((resolve) => setTimeout(resolve, 100));

    expect(mockPrefetch).toHaveBeenCalledWith(
      "/modal",
      expect.objectContaining({ method: "get" }),
      undefined,
    );
  });

  it("restores the explicit return URL including query parameters", async () => {
    const stack = createModalStack();
    const wrapper = mountLink(
      { returnUrl: "/users?filter=active&page=2" },
      stack,
    );

    await wrapper.get("a").trigger("click");

    const visitOptions = mockVisit.mock.calls[0]?.[1];
    visitOptions.onSuccess({
      component: "Users/Edit",
      props: { id: 1 },
      url: "/users/1/edit",
      version: null,
      clearHistory: false,
      encryptHistory: false,
    });

    expect(stack.getModal("modal-0")?.baseUrl).toBe("/users?filter=active&page=2");
  });
});
