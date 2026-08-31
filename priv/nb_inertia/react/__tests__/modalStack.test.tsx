import React from "react";
import { describe, it, expect, vi, beforeEach } from "vite-plus/test";
import { renderHook, act } from "@testing-library/react";
import { ModalStackProvider, useModalStack } from "../modals";

const { mockVisit, mockOn, mockPrefetch, mockGetCached, eventListeners } =
  vi.hoisted(() => {
    const eventListeners = new Map<string, (event: CustomEvent) => void>();

    return {
      mockVisit: vi.fn(),
      mockPrefetch: vi.fn(),
      mockGetCached: vi.fn(() => ({})),
      eventListeners,
      mockOn: vi.fn((event: string, callback: (event: CustomEvent) => void) => {
        eventListeners.set(event, callback);
        return () => eventListeners.delete(event);
      }),
    };
  });

vi.mock("@inertiajs/react", () => ({
  router: {
    visit: mockVisit,
    on: mockOn,
    prefetch: mockPrefetch,
    getCached: mockGetCached,
  },
}));

vi.mock("../../shared/routerCompat", () => ({
  routerPrefetch: mockPrefetch,
}));

describe("ModalStackProvider (React)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    eventListeners.clear();
    mockGetCached.mockReturnValue({});
    window.history.replaceState({}, "", "/users?page=2");
  });

  it("opens loading modals through visitModal and sends modal headers", () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider>{children}</ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.visitModal("/users/1/edit");
    });

    expect(result.current.modals).toHaveLength(1);
    expect(result.current.modals[0]?.loading).toBe(true);
    expect(result.current.modals[0]?.returnUrl).toBe(
      "http://localhost:3000/users?page=2",
    );
    expect(mockVisit).toHaveBeenCalledWith(
      "/users/1/edit",
      expect.objectContaining({
        method: "get",
        preserveState: true,
        preserveScroll: true,
        headers: {
          "x-inertia-modal": "true",
          "x-inertia-modal-base-url": "http://localhost:3000/users?page=2",
        },
      }),
    );
  });

  it("preserves Inertia 3.7 visit options when opening a modal imperatively", () => {
    const onFinish = vi.fn();
    const onSuccess = vi.fn();
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider>{children}</ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.visitModal("/users/1/edit", {
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ["user"],
        except: ["audit"],
        reset: ["users"],
        invalidateCacheTags: "users",
        fresh: true,
        onFinish,
        onSuccess,
      });
    });

    expect(mockVisit).toHaveBeenCalledWith(
      "/users/1/edit",
      expect.objectContaining({
        async: true,
        viewTransition: true,
        preserveErrors: true,
        only: ["user"],
        except: ["audit"],
        reset: ["users"],
        invalidateCacheTags: "users",
        fresh: true,
        onFinish,
        onSuccess,
      }),
    );
  });

  it("assembles prefetched modals from the Inertia HttpResponse data payload", async () => {
    const Component = () => <div>Prefetched modal</div>;
    const resolveComponent = vi.fn().mockResolvedValue(Component);
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider resolveComponent={resolveComponent}>
        {children}
      </ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.prefetchModal!("/users/1", { cacheFor: "5s" });
    });

    expect(mockPrefetch).toHaveBeenCalledWith(
      "/users/1",
      expect.objectContaining({ preserveState: true }),
      { cacheFor: "5s" },
    );

    await act(async () => {
      eventListeners.get("prefetched")?.({
        detail: {
          response: {
            data: {
              component: "Users/Index",
              props: {
                _nb_modal: {
                  component: "Users/Edit",
                  props: { id: 1 },
                  url: "/users/1",
                  baseUrl: "/users",
                },
              },
              url: "/users/1",
            },
            status: 200,
            headers: {},
          },
        },
      } as CustomEvent);
      await Promise.resolve();
    });

    expect(resolveComponent).toHaveBeenCalledWith("Users/Edit");
    expect(result.current.getPrefetchedModal!("/users/1")).toMatchObject({
      component: Component,
      data: {
        component: "Users/Edit",
        props: { id: 1 },
      },
    });
  });

  it("does not pass undefined cache options and never reuses a zero-duration cache", async () => {
    const Component = () => <div>No-cache modal</div>;
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider resolveComponent={() => Promise.resolve(Component)}>
        {children}
      </ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.prefetchModal!("/uncached");
    });
    expect(mockPrefetch).toHaveBeenLastCalledWith(
      "/uncached",
      expect.objectContaining({ preserveState: true }),
      undefined,
    );

    act(() => {
      result.current.prefetchModal!("/no-cache", { cacheFor: 0 });
    });

    await act(async () => {
      eventListeners.get("prefetched")?.({
        detail: {
          response: {
            data: {
              component: "Users/Index",
              props: {
                _nb_modal: {
                  component: "Users/Edit",
                  url: "/no-cache",
                },
              },
              url: "/no-cache",
            },
          },
        },
      } as CustomEvent);
      await Promise.resolve();
    });

    expect(result.current.getPrefetchedModal!("/no-cache")).toBeUndefined();
  });

  it("releases failed and non-modal prefetches so they can be retried", () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <ModalStackProvider resolveComponent={() => Promise.resolve(() => null)}>
        {children}
      </ModalStackProvider>
    );

    const { result } = renderHook(() => useModalStack(), { wrapper });

    act(() => {
      result.current.prefetchModal!("/cancelled");
    });
    const cancelledRequest = mockPrefetch.mock.calls[0]?.[1];
    act(() => {
      void cancelledRequest.onCancel();
    });
    act(() => {
      result.current.prefetchModal!("/cancelled");
    });

    expect(mockPrefetch).toHaveBeenCalledTimes(2);

    act(() => {
      result.current.prefetchModal!("/plain-page");
    });
    act(() => {
      eventListeners.get("prefetched")?.({
        detail: {
          response: {
            data: {
              component: "Users/Index",
              props: {},
              url: "/plain-page",
            },
          },
          visit: { url: new URL("/plain-page", window.location.href) },
        },
      } as CustomEvent);
    });
    act(() => {
      result.current.prefetchModal!("/plain-page");
    });

    expect(mockPrefetch).toHaveBeenCalledTimes(4);
  });
});
