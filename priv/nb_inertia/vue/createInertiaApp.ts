/**
 * Production-friendly Vue entrypoint.
 *
 * The schema runtime is an optional dynamic import. Apps that do not pass a
 * page registry (or explicitly set `mode: 'off'`) load only the official
 * Inertia adapter and never request the runtime chunk.
 */

import type {
  CreateInertiaAppOptions,
  CreateInertiaAppOptionsForCSR,
  CreateInertiaAppOptionsForSSR,
  HeadManagerOnUpdateCallback,
  HeadManagerTitleCallback,
  InertiaAppSSRResponse,
  Page,
  PageProps,
  ServerHeadOption,
  SharedPageProps,
} from '@inertiajs/core';
import {
  App as InertiaApp,
  createInertiaApp as createOfficialInertiaApp,
  router as inertiaRouter,
} from '@inertiajs/vue3';
import type { App as VueApp, DefineComponent, Plugin } from 'vue';
import type { PageSchemaAppOptions, PageSchemaRuntimeOptions } from '../shared/schemaRuntime';

const RUNTIME_CONFIG_GLOBAL = '__NB_INERTIA_PAGE_SCHEMA_RUNTIME__';

type ComponentResolver = (
  name: string,
  page?: Page<SharedPageProps>,
) => DefineComponent | Promise<DefineComponent> | { default: DefineComponent };

type InertiaAppProps<SharedProps extends PageProps = PageProps> = {
  initialPage: Page<SharedProps>;
  initialComponent?: DefineComponent;
  resolveComponent?: (name: string, page?: Page) => DefineComponent | Promise<DefineComponent>;
  titleCallback?: HeadManagerTitleCallback;
  onHeadUpdate?: HeadManagerOnUpdateCallback;
  defaultLayout?: (name: string, page: Page) => unknown;
  serverHead?: ServerHeadOption;
};

type SetupOptions<ElementType, SharedProps extends PageProps> = {
  el: ElementType;
  App: typeof InertiaApp;
  props: InertiaAppProps<SharedProps>;
  plugin: Plugin;
};

type VueWithApp<SharedProps extends PageProps> = (
  app: VueApp,
  options: { ssr: boolean; page: Page<SharedProps> },
) => void;

type VueInertiaAppConfig = {};

type InertiaAppOptionsForCSR<SharedProps extends PageProps> = CreateInertiaAppOptionsForCSR<
  SharedProps,
  ComponentResolver,
  SetupOptions<HTMLElement, SharedProps>,
  void,
  VueInertiaAppConfig
> & {
  withApp?: never;
};

type InertiaAppOptionsForSSR<SharedProps extends PageProps> = CreateInertiaAppOptionsForSSR<
  SharedProps,
  ComponentResolver,
  SetupOptions<null, SharedProps>,
  VueApp,
  VueInertiaAppConfig
> & {
  render: (app: VueApp) => Promise<string>;
  withApp?: never;
};

type InertiaAppOptionsAuto<SharedProps extends PageProps> = Omit<
  CreateInertiaAppOptions<
    ComponentResolver,
    SetupOptions<HTMLElement | null, SharedProps>,
    VueApp | void,
    VueInertiaAppConfig
  >,
  'setup'
> & {
  page?: Page<SharedProps>;
  render?: undefined;
} & (
    | { setup?: undefined; withApp?: VueWithApp<SharedProps> }
    | {
        setup: (options: SetupOptions<HTMLElement | null, SharedProps>) => VueApp | void;
        withApp?: never;
      }
  );

type RenderToString = (app: VueApp) => Promise<string>;
type RenderFunction<SharedProps extends PageProps> = (
  page: Page<SharedProps>,
  renderToString: RenderToString,
) => Promise<InertiaAppSSRResponse>;
type DefaultSharedProps = PageProps & Omit<SharedPageProps, keyof PageProps>;

/**
 * Options accepted by the Vue adapter, including nb_inertia's optional page
 * schema configuration. The three official modes intentionally remain
 * separate so CSR, SSR, and automatic setup retain their native constraints.
 */
export type VueCreateInertiaAppOptions<SharedProps extends PageProps = DefaultSharedProps> =
  | (InertiaAppOptionsForCSR<SharedProps> & PageSchemaAppOptions)
  | (InertiaAppOptionsForSSR<SharedProps> & PageSchemaAppOptions)
  | (InertiaAppOptionsAuto<SharedProps> & PageSchemaAppOptions);

type RuntimeConfig = PageSchemaRuntimeOptions | false | undefined;

function globalConfig(): RuntimeConfig {
  try {
    return (globalThis as Record<string, unknown>)[RUNTIME_CONFIG_GLOBAL] as RuntimeConfig;
  } catch {
    return undefined;
  }
}

function configNeedsRuntime(config: unknown): boolean {
  if (config === false || !config || typeof config !== 'object') return false;
  const value = config as Record<string, unknown>;
  return (
    value.enabled !== false &&
    value.mode !== 'off' &&
    value.policy !== 'off' &&
    value.registry != null
  );
}

function appNeedsRuntime(options: VueCreateInertiaAppOptions | undefined): boolean {
  if (!options) return configNeedsRuntime(globalConfig());

  const local = options.schemaRuntime ?? options.pageSchemaRuntime;
  if (local === false) return false;
  if (local && typeof local === 'object') {
    if (local.enabled === false || local.mode === 'off' || local.policy === 'off') return false;
    if ('registry' in local && local.registry == null) return false;
  }
  if (local && configNeedsRuntime(local)) return true;
  if (options.pageSchemas != null) return true;
  return configNeedsRuntime(globalConfig());
}

function withoutRuntimeOptions(
  options: VueCreateInertiaAppOptions,
):
  | InertiaAppOptionsForCSR<DefaultSharedProps>
  | InertiaAppOptionsForSSR<DefaultSharedProps>
  | InertiaAppOptionsAuto<DefaultSharedProps> {
  const {
    schemaRuntime: _schemaRuntime,
    pageSchemaRuntime: _pageSchemaRuntime,
    pageSchemas: _pageSchemas,
    ...coreOptions
  } = options as VueCreateInertiaAppOptions & Record<string, unknown>;
  void _schemaRuntime;
  void _pageSchemaRuntime;
  void _pageSchemas;
  return coreOptions as
    | InertiaAppOptionsForCSR<DefaultSharedProps>
    | InertiaAppOptionsForSSR<DefaultSharedProps>
    | InertiaAppOptionsAuto<DefaultSharedProps>;
}

/** Configure adapter defaults without importing the optional runtime chunk. */
export function configurePageSchemaRuntime(options: RuntimeConfig): RuntimeConfig {
  try {
    if (options === undefined) {
      delete (globalThis as Record<string, unknown>)[RUNTIME_CONFIG_GLOBAL];
    } else {
      (globalThis as Record<string, unknown>)[RUNTIME_CONFIG_GLOBAL] = options;
    }
  } catch {
    // Restricted SSR hosts may not allow global properties. Per-app options
    // remain the preferred SSR configuration path.
  }
  return options;
}

export function getPageSchemaRuntimeConfig(): RuntimeConfig {
  return globalConfig();
}

export function clearPageSchemaRuntimeConfig(): void {
  configurePageSchemaRuntime(undefined);
}

/**
 * Vue's official `createInertiaApp` with optional page-contract decoding.
 * The dynamic import is inside the runtime-request branch so disabled
 * production apps can tree-shake the complete schema implementation.
 */
export async function createInertiaApp<SharedProps extends PageProps = DefaultSharedProps>(
  options: InertiaAppOptionsForCSR<SharedProps> & PageSchemaAppOptions,
): Promise<void>;
export async function createInertiaApp<SharedProps extends PageProps = DefaultSharedProps>(
  options: InertiaAppOptionsForSSR<SharedProps> & PageSchemaAppOptions,
): Promise<InertiaAppSSRResponse>;
export async function createInertiaApp<SharedProps extends PageProps = DefaultSharedProps>(
  options?: InertiaAppOptionsAuto<SharedProps> & PageSchemaAppOptions,
): Promise<void | RenderFunction<SharedProps>>;
export async function createInertiaApp(
  options?: VueCreateInertiaAppOptions,
): Promise<void | InertiaAppSSRResponse | RenderFunction<PageProps>>;
export async function createInertiaApp(options?: VueCreateInertiaAppOptions): Promise<unknown> {
  if (!options) return createOfficialInertiaApp();

  if (!appNeedsRuntime(options)) {
    return (createOfficialInertiaApp as unknown as (options: unknown) => unknown)(
      withoutRuntimeOptions(options),
    );
  }

  const { createSchemaAwareInertiaApp } = await import('../shared/schemaRuntime');
  return createSchemaAwareInertiaApp(
    createOfficialInertiaApp as unknown as (options: Record<string, unknown>) => unknown,
    options as PageSchemaAppOptions & Record<string, unknown>,
    inertiaRouter,
  );
}

export default createInertiaApp;
