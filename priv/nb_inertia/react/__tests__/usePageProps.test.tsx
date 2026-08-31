import { renderHook } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vite-plus/test";
import { usePage as inertiaUsePage } from "@inertiajs/react";
import type { PropsWithChildren } from "react";
import { ModalPageProvider } from "../modals";
import { createUsePageProps, PagePropsComponentMismatchError, usePageProps } from "../usePageProps";

vi.mock("@inertiajs/react", () => ({
  usePage: vi.fn(),
}));

interface Pages {
  "Users/Index": { users: Array<{ id: number }> };
  Dashboard: { title: string };
}

const mockUsePage = vi.mocked(inertiaUsePage);

describe("usePageProps (React)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUsePage.mockReturnValue({
      component: "Users/Index",
      props: { users: [{ id: 1 }] },
    } as never);
  });

  it("reads official usePage and returns the map entry for the expected component", () => {
    const { result } = renderHook(() => usePageProps("Users/Index"));

    expect(result.current).toEqual({ users: [{ id: 1 }] });
    expect(mockUsePage).toHaveBeenCalledTimes(1);
  });

  it("binds a generated Pages map through the framework factory", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: true });
    const { result } = renderHook(() => useGeneratedPageProps("Users/Index"));

    expect(result.current.users).toHaveLength(1);
  });

  it("reads typed props from a modal page context without calling official usePage", () => {
    const wrapper = ({ children }: PropsWithChildren) => (
      <ModalPageProvider
        component="Users/Index"
        props={{ users: [{ id: 2 }] }}
        url="/users/2/edit"
        baseUrl="/users"
      >
        {children}
      </ModalPageProvider>
    );

    const useGeneratedPageProps = createUsePageProps<Pages>({ development: true });
    const { result } = renderHook(() => useGeneratedPageProps("Users/Index"), { wrapper });

    expect(result.current.users).toEqual([{ id: 2 }]);
    expect(mockUsePage).not.toHaveBeenCalled();
  });

  it("throws a useful development error when the component is not the expected page", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: true });
    expect(() => renderHook(() => useGeneratedPageProps("Dashboard"))).toThrow(
      PagePropsComponentMismatchError,
    );
  });

  it("keeps production page access non-throwing for a mismatched component", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: false });
    const { result } = renderHook(() => useGeneratedPageProps("Dashboard"));

    expect(result.current).toEqual({ users: [{ id: 1 }] });
  });
});
