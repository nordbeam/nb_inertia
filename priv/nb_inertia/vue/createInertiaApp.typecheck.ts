/**
 * Compile-time coverage for the Vue createInertiaApp overloads.
 *
 * This file is intentionally not imported at runtime. It is included by the
 * Vue package tsconfig so CI catches regressions in the official CSR, SSR,
 * and automatic setup contracts.
 */

import type { Page } from "@inertiajs/core";
import { type App as VueApp, type DefineComponent } from "vue";
import { createInertiaApp } from "./createInertiaApp";

type SharedProps = {
  auth: {
    id: number;
  };
};

const component = {} as DefineComponent;
const page = {
  component: "Dashboard",
  props: { auth: { id: 1 }, errors: {} },
  url: "/dashboard",
  version: null,
  rescuedProps: [],
  flash: {},
  rememberedState: {},
} as Page<SharedProps>;

const title = (value: string, currentPage: Page) => `${value} · ${currentPage.component}`;
const layout = (name: string, currentPage: Page) => ({ name, currentPage });

void createInertiaApp<SharedProps>({
  resolve: async () => component,
  setup: ({ el, props, plugin }) => {
    void el;
    void props;
    void plugin;
  },
  title,
  layout,
  serverHead: true,
  http: { xsrfCookieName: "XSRF-TOKEN" },
  pageSchemas: { get: () => undefined },
});

void createInertiaApp<SharedProps>({
  resolve: async () => component,
  setup: ({ el, props, plugin }) => {
    void el;
    void props;
    void plugin;
    return {} as VueApp;
  },
  page,
  render: async () => "",
  title,
  layout,
  serverHead: true,
  schemaRuntime: { mode: "throw", registry: { get: () => undefined } },
});

void createInertiaApp<SharedProps>({
  resolve: async () => component,
  withApp: (app, options) => {
    void app;
    void options.page.props;
  },
  title,
  layout,
  serverHead: true,
});
