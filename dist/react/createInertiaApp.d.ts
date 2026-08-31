import { createInertiaApp as createOfficialInertiaApp } from '@inertiajs/react';
import { PageSchemaAppOptions, PageSchemaRuntimeOptions } from '../shared/schemaRuntime';
type OfficialCreateInertiaAppOptions = Parameters<typeof createOfficialInertiaApp>[0];
export type ReactCreateInertiaAppOptions = OfficialCreateInertiaAppOptions & PageSchemaAppOptions;
type RuntimeConfig = PageSchemaRuntimeOptions | false | undefined;
/**
 * Configure adapter defaults without importing the schema runtime.  The
 * shared runtime reads this same global marker when its lazy chunk is first
 * loaded, so configuration remains reliable across split bundles.
 */
export declare function configurePageSchemaRuntime(options: RuntimeConfig): RuntimeConfig;
export declare function getPageSchemaRuntimeConfig(): RuntimeConfig;
export declare function clearPageSchemaRuntimeConfig(): void;
export type SchemaAwareCreateInertiaApp = typeof createOfficialInertiaApp & ((options?: ReactCreateInertiaAppOptions) => ReturnType<typeof createOfficialInertiaApp>);
export declare const createInertiaApp: SchemaAwareCreateInertiaApp;
export default createInertiaApp;
//# sourceMappingURL=createInertiaApp.d.ts.map