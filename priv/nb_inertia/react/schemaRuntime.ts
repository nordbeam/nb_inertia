/**
 * Full React schema-runtime entrypoint.
 *
 * Import `react/createInertiaApp` when only the adapter is needed: that entry
 * lazily loads this optional runtime chunk after a registry is configured.
 */

export { createInertiaApp, default } from './createInertiaApp';
export type { ReactCreateInertiaAppOptions } from './createInertiaApp';

export {
  PageSchemaRuntimeError,
  clearPageSchemaRuntimeConfig,
  configurePageSchemaRuntime,
  createPageSchemaRegistry,
  createPageSchemaRuntime,
  getPageSchemaRuntimeConfig,
  installPageSchemaRuntime,
  isPageSchemaRuntimeError,
  resolvePageSchemaRuntimeOptions,
  type PagePropSchema,
  type PageSchema,
  type PageSchemaValue,
  type PageSchemaAppOptions,
  type PageSchemaRegistry,
  type PageSchemaRegistryLike,
  type PageSchemaRuntimeOptions,
  type SchemaFailure,
  type SchemaFailureResult,
  type SchemaFailureReporter,
  type SchemaParser,
  type SchemaResult,
  type SchemaSuccess,
  type SchemaRuntime,
  type SchemaRuntimeMode,
  type SchemaRuntimePhase,
} from '../shared/schemaRuntime';

export {
  createUsePageProps,
  usePageProps,
  type PageMap,
  type PagePropsHookOptions,
  type PagePropsMismatch,
  type PageSnapshotLike,
  type UsePageProps,
  PagePropsComponentMismatchError,
} from './usePageProps';
