/**
 * Framework-neutral page-scoped props accessor.
 *
 * Generated `Pages` maps are TypeScript-only, so the runtime cannot derive a
 * page type from a component string.  Consumers bind their generated map once
 * with `createPagePropsHook` and receive a normal one-argument hook whose
 * signature is `usePageProps<K extends keyof Pages>(expected: K) => Pages[K]`.
 * The accessor supplied by a framework adapter is deliberately tiny and can
 * call the official Inertia `usePage` hook without pulling in schema runtime
 * code.
 */

export interface PageSnapshotLike {
  component: string;
  props: unknown;
}

export type PageMap = object;

export type UsePageProps<Pages extends PageMap> = <K extends keyof Pages>(expected: K) => Pages[K];

export interface PagePropsMismatch {
  expected: string;
  actual: string;
}

export interface PagePropsHookOptions {
  /** Override environment detection in tests or host runtimes. */
  development?: boolean;
  /** Observe a mismatch before the development error is thrown. */
  onMismatch?: (mismatch: PagePropsMismatch) => void;
}

export class PagePropsComponentMismatchError extends Error {
  readonly expected: string;
  readonly actual: string;

  constructor(expected: string, actual: string) {
    super(`Expected Inertia page ${expected}, received ${actual}`);
    this.name = 'PagePropsComponentMismatchError';
    this.expected = expected;
    this.actual = actual;
  }
}

function isDevelopmentEnvironment(): boolean {
  const processLike = (globalThis as { process?: { env?: { NODE_ENV?: string } } }).process;
  if (processLike?.env?.NODE_ENV) return processLike.env.NODE_ENV !== 'production';

  // Vite replaces `import.meta.env.DEV` at build time.  Keeping this access
  // guarded makes the same module safe to import from Node SSR and test hosts.
  const importMeta = import.meta as ImportMeta & { env?: { DEV?: boolean } };
  return importMeta.env?.DEV ?? true;
}

/**
 * Bind a generated page map to a framework's current-page accessor.
 *
 * `getPage` is called only when the returned hook is invoked, which means a
 * React/Vue adapter can safely pass the official framework `usePage` hook.
 */
export function createPagePropsHook<Pages extends PageMap>(
  getPage: () => PageSnapshotLike,
  options: PagePropsHookOptions = {}
): UsePageProps<Pages> {
  return function usePageProps<K extends keyof Pages>(expected: K): Pages[K] {
    const current = getPage();
    const expectedName = String(expected);

    if ((options.development ?? isDevelopmentEnvironment()) && current.component !== expectedName) {
      const mismatch = { expected: expectedName, actual: current.component };
      options.onMismatch?.(mismatch);
      throw new PagePropsComponentMismatchError(mismatch.expected, mismatch.actual);
    }

    return current.props as Pages[K];
  };
}

/** Alias matching the generated helper name used by page-contract codegen. */
export function createUsePageProps<Pages extends PageMap>(
  getPage: () => PageSnapshotLike,
  options: PagePropsHookOptions = {}
): UsePageProps<Pages> {
  return createPagePropsHook<Pages>(getPage, options);
}
