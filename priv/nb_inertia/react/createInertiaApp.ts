/**
 * Production-friendly React entrypoint.
 *
 * The schema runtime is an optional dynamic import.  Apps that do not pass a
 * page registry (or explicitly set `mode: 'off'`) load only the official
 * Inertia adapter and never request the runtime chunk.
 */

import { createInertiaApp as createOfficialInertiaApp, router as inertiaRouter } from '@inertiajs/react';
import type {
  PageSchemaAppOptions,
  PageSchemaRuntimeOptions,
} from '../shared/schemaRuntime';

const RUNTIME_CONFIG_GLOBAL = '__NB_INERTIA_PAGE_SCHEMA_RUNTIME__';

type OfficialCreateInertiaAppOptions = Parameters<typeof createOfficialInertiaApp>[0];

export type ReactCreateInertiaAppOptions = OfficialCreateInertiaAppOptions & PageSchemaAppOptions;

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
  return value.enabled !== false && value.mode !== 'off' && value.policy !== 'off' && value.registry != null;
}

function appNeedsRuntime(options: ReactCreateInertiaAppOptions | undefined): boolean {
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

function withoutRuntimeOptions(options: ReactCreateInertiaAppOptions): OfficialCreateInertiaAppOptions {
  const {
    schemaRuntime: _schemaRuntime,
    pageSchemaRuntime: _pageSchemaRuntime,
    pageSchemas: _pageSchemas,
    ...coreOptions
  } = options as ReactCreateInertiaAppOptions & Record<string, unknown>;
  void _schemaRuntime;
  void _pageSchemaRuntime;
  void _pageSchemas;
  return coreOptions as OfficialCreateInertiaAppOptions;
}

/**
 * Configure adapter defaults without importing the schema runtime.  The
 * shared runtime reads this same global marker when its lazy chunk is first
 * loaded, so configuration remains reliable across split bundles.
 */
export function configurePageSchemaRuntime(options: RuntimeConfig): RuntimeConfig {
  try {
    if (options === undefined) {
      delete (globalThis as Record<string, unknown>)[RUNTIME_CONFIG_GLOBAL];
    } else {
      (globalThis as Record<string, unknown>)[RUNTIME_CONFIG_GLOBAL] = options;
    }
  } catch {
    // Restricted SSR hosts may not allow global properties. The lazy runtime
    // still accepts per-app options, which is the preferred SSR path.
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
 * React's official `createInertiaApp` with optional page-contract decoding.
 * The dynamic import is intentionally inside the runtime-request branch so
 * disabled production apps can tree-shake the complete schema implementation.
 */
async function createInertiaAppImpl(
  options?: ReactCreateInertiaAppOptions
): ReturnType<typeof createOfficialInertiaApp> {
  if (!options) return createOfficialInertiaApp();

  if (!appNeedsRuntime(options)) {
    return createOfficialInertiaApp(withoutRuntimeOptions(options));
  }

  const { createSchemaAwareInertiaApp } = await import('../shared/schemaRuntime');
  return createSchemaAwareInertiaApp(
    createOfficialInertiaApp as unknown as (options: Record<string, unknown>) => unknown,
    options as PageSchemaAppOptions & Record<string, unknown>,
    inertiaRouter
  ) as ReturnType<typeof createOfficialInertiaApp>;
}

export type SchemaAwareCreateInertiaApp = typeof createOfficialInertiaApp &
  ((options?: ReactCreateInertiaAppOptions) => ReturnType<typeof createOfficialInertiaApp>);

export const createInertiaApp = createInertiaAppImpl as SchemaAwareCreateInertiaApp;

export default createInertiaApp;
