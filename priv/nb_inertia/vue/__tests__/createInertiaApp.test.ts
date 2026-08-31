import { beforeEach, describe, expect, it, vi } from "vite-plus/test";
import { createInertiaApp } from "../createInertiaApp";

const { mockCreateOfficialInertiaApp } = vi.hoisted(() => ({
  mockCreateOfficialInertiaApp: vi.fn(),
}));

vi.mock("@inertiajs/vue3", () => ({
  createInertiaApp: mockCreateOfficialInertiaApp,
  router: {},
}));

describe("createInertiaApp (Vue)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockCreateOfficialInertiaApp.mockResolvedValue(undefined);
  });

  it("forwards official options while removing schema-only options when disabled", async () => {
    const resolve = vi.fn();
    const setup = vi.fn();
    const title = vi.fn();
    const layout = vi.fn();

    await createInertiaApp({
      resolve,
      setup,
      title,
      layout,
      serverHead: true,
      http: { xsrfCookieName: "XSRF-TOKEN" },
      schemaRuntime: false,
    });

    expect(mockCreateOfficialInertiaApp).toHaveBeenCalledTimes(1);
    expect(mockCreateOfficialInertiaApp).toHaveBeenCalledWith({
      resolve,
      setup,
      title,
      layout,
      serverHead: true,
      http: { xsrfCookieName: "XSRF-TOKEN" },
    });
  });

  it("preserves automatic setup when no options are supplied", async () => {
    await createInertiaApp();

    expect(mockCreateOfficialInertiaApp).toHaveBeenCalledWith();
  });
});
