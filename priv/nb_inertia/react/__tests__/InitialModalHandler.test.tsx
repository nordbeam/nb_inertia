import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vite-plus/test";
import type { Page } from "@inertiajs/core";
import { InitialModalHandler, ModalStackProvider, useModalStack } from "../modals";

let initialPage: Page;
const listeners = new Map<string, (event: any) => void>();

vi.mock("@inertiajs/react", () => ({
  usePage: () => initialPage,
  router: {
    on: (event: string, callback: (event: any) => void) => {
      listeners.set(event, callback);
      return () => listeners.delete(event);
    },
  },
}));

function StackInspector() {
  const { modals } = useModalStack();
  const name = (modals[0]?.props as { user?: { name?: string } } | undefined)?.user?.name ?? "none";

  return <div data-testid="modal-user-name">{name}</div>;
}

describe("InitialModalHandler (React)", () => {
  beforeEach(() => {
    listeners.clear();
    initialPage = {
      component: "Users/Index",
      props: {
        errors: {},
        _nb_modal: {
          component: "Users/Edit",
          props: { user: { name: "Alice" } },
          url: "/users/1/edit",
          baseUrl: "/users",
        },
      },
      url: "/users/1/edit",
      version: null,
      rescuedProps: [],
      flash: {},
      rememberedState: {},
    };
  });

  it("updates an existing modal when navigating to the same modal URL", async () => {
    render(
      <ModalStackProvider>
        <InitialModalHandler resolveComponent={async () => () => null} initialPage={initialPage} />
        <StackInspector />
      </ModalStackProvider>,
    );

    await waitFor(() => {
      expect(screen.getByTestId("modal-user-name")).toHaveTextContent("Alice");
    });

    listeners.get("navigate")?.({
      detail: {
        page: {
          props: {
            _nb_modal: {
              component: "Users/Edit",
              props: { user: { name: "Bob" } },
              url: "/users/1/edit",
              baseUrl: "/users",
            },
          },
        },
      },
    });

    await waitFor(() => {
      expect(screen.getByTestId("modal-user-name")).toHaveTextContent("Bob");
    });
  });

  it("keeps the context-based initial page fallback for existing integrations", async () => {
    render(
      <ModalStackProvider>
        <InitialModalHandler resolveComponent={async () => () => null} />
        <StackInspector />
      </ModalStackProvider>,
    );

    await waitFor(() => {
      expect(screen.getByTestId("modal-user-name")).toHaveTextContent("Alice");
    });
  });
});
