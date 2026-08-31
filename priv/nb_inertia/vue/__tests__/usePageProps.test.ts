import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { beforeEach, describe, expect, it, vi } from "vite-plus/test";
import { usePage as inertiaUsePage } from "@inertiajs/vue3";
import { createUsePageProps, PagePropsComponentMismatchError, usePageProps } from "../usePageProps";

vi.mock("@inertiajs/vue3", () => ({
  usePage: vi.fn(),
}));

interface Pages {
  "Users/Index": { users: Array<{ id: number }> };
  Dashboard: { title: string };
}

const mockUsePage = vi.mocked(inertiaUsePage);

describe("usePageProps (Vue)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUsePage.mockReturnValue({
      component: "Users/Index",
      props: { users: [{ id: 1 }] },
    } as never);
  });

  it("reads official usePage and returns the map entry for the expected component", () => {
    const TestComponent = defineComponent({
      setup() {
        const props = usePageProps("Users/Index") as Pages["Users/Index"];
        return () => h("span", String(props.users[0].id));
      },
    });

    expect(mount(TestComponent).text()).toBe("1");
    expect(mockUsePage).toHaveBeenCalledTimes(1);
  });

  it("binds a generated Pages map through the framework factory", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: true });
    const TestComponent = defineComponent({
      setup() {
        const props = useGeneratedPageProps("Users/Index");
        return () => h("span", String(props.users.length));
      },
    });

    expect(mount(TestComponent).text()).toBe("1");
  });

  it("throws a useful development error when the component is not the expected page", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: true });
    const TestComponent = defineComponent({
      setup() {
        useGeneratedPageProps("Dashboard");
        return () => h("span");
      },
    });

    expect(() => mount(TestComponent)).toThrow(PagePropsComponentMismatchError);
  });

  it("keeps production page access non-throwing for a mismatched component", () => {
    const useGeneratedPageProps = createUsePageProps<Pages>({ development: false });
    const TestComponent = defineComponent({
      setup() {
        const props = useGeneratedPageProps("Dashboard");
        return () => h("span", String((props as unknown as { users: unknown[] }).users.length));
      },
    });

    expect(mount(TestComponent).text()).toBe("1");
  });
});
