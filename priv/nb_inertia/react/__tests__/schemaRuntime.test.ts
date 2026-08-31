import { beforeEach, describe, expect, it, vi } from 'vite-plus/test';
import { z } from 'zod';
import {
  PageSchemaRuntimeError,
  createPageSchemaRegistry,
  createPageSchemaRuntime,
  clearPageSchemaRuntimeConfig,
  configurePageSchemaRuntime,
  getPageSchemaRuntimeConfig,
  installPageSchemaRuntime,
  type InertiaRouterLike,
  type PageLike,
  type SchemaFailure,
} from '../../shared/schemaRuntime';

function page(component: string, props: Record<string, unknown>): PageLike {
  return { component, props, url: '/', version: 'test' };
}

describe('page schema runtime', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    clearPageSchemaRuntimeConfig();
    window.history.replaceState({}, '', '/');
  });

  it('parses once and preserves untouched prop identity', () => {
    const untouched = { id: 10 };
    const parse = vi.fn((value: unknown) => ({ success: true as const, data: Number(value) }));
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: { fields: { count: { parse } } },
      }),
      mode: 'throw',
    });
    const current = page('Users', { count: '2', untouched });

    const processed = runtime.processPage(current, 'initial') as PageLike;
    const repeated = runtime.processPage(current, 'initial');

    expect(parse).toHaveBeenCalledTimes(1);
    expect((processed.props as Record<string, unknown>).count).toBe(2);
    expect((processed.props as Record<string, unknown>).untouched).toBe(untouched);
    expect(repeated).toBe(processed);
  });

  it('reports validation failures and omits the invalid wire value', () => {
    const failures: SchemaFailure[] = [];
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: {
          fields: {
            count: { validate: () => false },
          },
        },
      }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });
    const processed = runtime.processPage(
      page('Users', { count: 'not-a-number', keep: true }),
      'navigation',
    ) as PageLike;

    expect(processed.props).not.toHaveProperty('count');
    expect((processed.props as Record<string, unknown>).keep).toBe(true);
    expect(failures).toHaveLength(1);
    expect(failures[0].kind).toBe('validation');
    expect(failures[0].stage).toBe('validation');
  });

  it('never falls back to invalid wire data after a transform/decode failure', () => {
    const failures: SchemaFailure[] = [];
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: {
          fields: {
            name: {
              transforms: true,
              safeParse: () => ({ success: false, error: new Error('bad payload') }),
            },
          },
        },
      }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });
    const processed = runtime.processPage(
      page('Users', { name: 'wire value' }),
      'navigation',
    ) as PageLike;

    expect(processed.props).not.toHaveProperty('name');
    expect(failures[0].kind).toBe('decode');
    expect(failures[0].stage).toBe('decode');
  });

  it('classifies whole-page Zod-style issues as validation and sanitizes issue paths', () => {
    const failures: SchemaFailure[] = [];
    const keep = { stable: true };
    const safeParse = vi.fn(() => ({
      success: false as const,
      error: {
        issues: [
          { path: ['bad', 'nested'], message: 'invalid value' },
          { path: '$.unsafe.value', message: 'invalid value' },
          { path: ['__proto__', 'polluted'], message: 'must not be copied' },
        ],
      },
    }));
    const runtime = createPageSchemaRuntime({
      // `transforms` is a registry capability marker, not a blanket decode
      // marker. Plain Zod validation failures remain validation failures.
      registry: { transforms: true, get: () => ({ safeParse }) },
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    const processed = runtime.processPage(
      page('Users', { bad: 'wire', unsafe: 'wire', keep }),
      'navigation',
    ) as PageLike;

    expect(safeParse).toHaveBeenCalledTimes(1);
    expect(failures[0].kind).toBe('validation');
    expect(failures[0].stage).toBe('validation');
    expect(processed.props).not.toHaveProperty('bad');
    expect(processed.props).not.toHaveProperty('unsafe');
    expect((processed.props as Record<string, unknown>).keep).toBe(keep);
    expect(Object.prototype.hasOwnProperty.call(processed.props, '$')).toBe(false);
    expect(Object.prototype.hasOwnProperty.call(processed.props, '__proto__')).toBe(false);
  });

  it('classifies a marked whole-page transform failure as decode', () => {
    const failures: SchemaFailure[] = [];
    const schema = {
      schema: {
        safeParse: () => ({
          success: false as const,
          error: { issues: [{ path: ['createdAt'], message: 'not an ISO date' }] },
        }),
      },
      transforms: true,
    };
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({ Users: schema }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    const processed = runtime.processPage(
      page('Users', { createdAt: 'not-a-date' }),
      'initial',
    ) as PageLike;

    expect(processed.props).toEqual({});
    expect(failures[0].kind).toBe('decode');
    expect(failures[0].stage).toBe('decode');
  });

  it('does not require untouched fields during partial or deferred visits', () => {
    const parse = vi.fn((value: unknown) => ({
      success: true as const,
      data: String(value).toUpperCase(),
    }));
    const validate = vi.fn(() => false);
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: {
          validate,
          fields: {
            untouched: { required: true, validate },
            changed: { parse },
          },
        },
      }),
      mode: 'throw',
    });

    const partial = runtime.processPage(page('Users', { changed: 'new' }), 'partial') as PageLike;
    const deferred = runtime.processPage(
      page('Users', { changed: 'later' }),
      'deferred',
    ) as PageLike;

    expect((partial.props as Record<string, unknown>).changed).toBe('NEW');
    expect((deferred.props as Record<string, unknown>).changed).toBe('LATER');
    expect(validate).not.toHaveBeenCalled();
    expect(parse).toHaveBeenCalledTimes(2);
  });

  it('keeps valid partial fields while omitting only invalid fields in report mode', () => {
    const untouched = { id: 10 };
    const failures: SchemaFailure[] = [];
    const validParse = vi.fn((value: unknown) => ({ success: true as const, data: Number(value) }));
    const invalidSafeParse = vi.fn(() => ({
      success: false as const,
      error: { issues: [{ path: ['invalid'], message: 'bad value' }] },
    }));
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: {
          fields: {
            count: { parse: validParse },
            invalid: { safeParse: invalidSafeParse },
          },
        },
      }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    const processed = runtime.processPage(
      page('Users', { count: '2', invalid: 'wire', untouched }),
      'partial',
    ) as PageLike;
    const processedProps = processed.props as Record<string, unknown>;

    expect(processedProps.count).toBe(2);
    expect(processedProps).not.toHaveProperty('invalid');
    expect(processedProps.untouched).toBe(untouched);
    expect(failures).toHaveLength(1);
    expect(failures[0].kind).toBe('validation');
  });

  it('distinguishes date decode failures from ordinary field validation', () => {
    const failures: SchemaFailure[] = [];
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        Users: {
          fields: {
            createdAt: {
              transforms: true,
              safeParse: () => ({
                success: false as const,
                error: { issues: [{ path: [], message: 'invalid date' }] },
              }),
            },
            name: {
              safeParse: () => ({
                success: false as const,
                error: { issues: [{ path: [], message: 'required' }] },
              }),
            },
          },
        },
      }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    runtime.processPage(page('Users', { createdAt: 'bad', name: 42 }), 'navigation');

    expect(failures.map((failure) => [failure.prop, failure.kind])).toEqual([
      ['createdAt', 'decode'],
      ['name', 'validation'],
    ]);
  });

  it('consumes the generated fullSchema/fields registry shape without reparsing', () => {
    const untouched = { stable: true };
    const fullParse = vi.fn((value: unknown) => ({
      success: true as const,
      data: {
        ...(value as Record<string, unknown>),
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      },
    }));
    const fieldParse = vi.fn((value: unknown) => ({
      success: true as const,
      data: new Date(String(value)),
    }));
    const entry = {
      schema: { safeParse: fullParse },
      fullSchema: { safeParse: fullParse },
      wireSchema: { safeParse: fullParse },
      fields: {
        title: { safeParse: (value: unknown) => ({ success: true as const, data: String(value) }) },
        createdAt: {
          schema: { safeParse: fieldParse },
          safeParse: fieldParse,
          transforms: true,
          decodeEnabled: true,
          isTransform: true,
        },
      },
      shape: {},
      propertySchemas: {},
      required: ['title'],
      transformFields: { createdAt: true },
    };
    const runtime = createPageSchemaRuntime({
      registry: { get: () => entry },
      mode: 'report',
      onFailure: () => undefined,
    });

    const complete = runtime.processPage(
      page('Users', { title: 'Users', createdAt: '2026-01-01T00:00:00.000Z', untouched }),
      'initial',
    ) as PageLike;
    const partial = runtime.processPage(
      page('Users', { createdAt: '2026-02-01T00:00:00.000Z', untouched }),
      'partial',
    ) as PageLike;

    // The generated field map is authoritative at the lifecycle boundary;
    // fullSchema is reserved for explicit whole-page decoding helpers.
    expect(fullParse).not.toHaveBeenCalled();
    expect(fieldParse).toHaveBeenCalledTimes(2);
    expect((complete.props as Record<string, unknown>).createdAt).toBeInstanceOf(Date);
    expect((complete.props as Record<string, unknown>).untouched).toBe(untouched);
    expect((partial.props as Record<string, unknown>).createdAt).toBeInstanceOf(Date);
    expect((partial.props as Record<string, unknown>).untouched).toBe(untouched);
  });

  it('detects nested Zod 4 codecs while keeping plain object errors as validation', () => {
    const failures: SchemaFailure[] = [];
    const dateSchema = z.codec(z.iso.datetime(), z.date(), {
      decode: (value) => new Date(value),
      encode: (value) => value.toISOString(),
    });
    const generatedSchema = z.object({ createdAt: dateSchema, name: z.string() });
    const runtime = createPageSchemaRuntime({
      registry: { get: () => generatedSchema },
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    runtime.processPage(page('Users', { createdAt: 'not-a-date', name: 42 }), 'initial');

    expect(failures).toHaveLength(1);
    expect(failures[0].kind).toBe('decode');
    expect(failures[0].stage).toBe('decode');

    const plainFailures: SchemaFailure[] = [];
    const plainRuntime = createPageSchemaRuntime({
      registry: { get: () => z.object({ name: z.string() }) },
      mode: 'report',
      onFailure: (failure) => plainFailures.push(failure),
    });
    plainRuntime.processPage(page('Users', { name: 42 }), 'initial');
    expect(plainFailures[0].kind).toBe('validation');
  });

  it('uses configured report policy and can clear it without loading framework adapters', () => {
    const failures: SchemaFailure[] = [];
    configurePageSchemaRuntime({
      registry: createPageSchemaRegistry({ Users: { fields: { id: { validate: () => false } } } }),
      mode: 'report',
      onFailure: (failure) => failures.push(failure),
    });

    const runtime = createPageSchemaRuntime();
    expect(runtime.mode).toBe('report');
    expect(runtime.enabled).toBe(true);
    expect(
      (runtime.processPage(page('Users', { id: 'bad' }), 'navigation') as PageLike).props,
    ).toEqual({});
    expect(failures).toHaveLength(1);

    clearPageSchemaRuntimeConfig();
    expect(getPageSchemaRuntimeConfig()).toBeUndefined();
  });

  it('throws before the router resolver commits an invalid page', () => {
    const resolve = vi.fn(() => Promise.resolve({}));
    const router: InertiaRouterLike & { params?: Record<string, unknown> } = {
      init(params) {
        this.params = params;
      },
      on: () => () => undefined,
    };
    installPageSchemaRuntime(
      {
        registry: createPageSchemaRegistry({
          Users: { fields: { id: { validate: (value) => value === 'ok' } } },
        }),
        mode: 'throw',
      },
      router,
    );

    router.init?.({
      initialPage: page('Users', { id: 'ok' }),
      resolveComponent: resolve,
    });

    const resolver = router.params?.resolveComponent as (name: string, value: PageLike) => unknown;
    expect(() => resolver('Users', page('Users', { id: 'bad' }))).toThrow(PageSchemaRuntimeError);
    expect(resolve).not.toHaveBeenCalled();
  });

  it('validates modal props and preserves the surrounding page', () => {
    const background = { label: 'background' };
    const modalProps = { id: '42' };
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        'Users/Show': { fields: { id: { parse: (value) => Number(value) } } },
      }),
      mode: 'throw',
    });
    const current = page('Users/Index', {
      background,
      _nb_modal: {
        component: 'Users/Show',
        props: modalProps,
      },
    });
    const processed = runtime.processPage(current, 'navigation') as PageLike;
    const processedProps = processed.props as Record<string, any>;

    expect(processedProps.background).toBe(background);
    expect(processedProps._nb_modal.props).not.toBe(modalProps);
    expect(processedProps._nb_modal.props.id).toBe(42);
  });

  it('updates prefetched JSON so modal caches receive decoded props', () => {
    const runtime = createPageSchemaRuntime({
      registry: createPageSchemaRegistry({
        'Users/Index': { fields: { title: { parse: (value) => String(value).toUpperCase() } } },
      }),
      mode: 'throw',
    });
    const response = {
      data: JSON.stringify({ component: 'Users/Index', props: { title: 'users' }, url: '/' }),
    };

    // `processPage` is the pure part used by the prefetch event adapter.  The
    // event adapter is exercised through a tiny router installation below.
    const callbacks = new Map<string, (event: unknown) => unknown>();
    const router: InertiaRouterLike = {
      init: () => undefined,
      on: (name, callback) => {
        callbacks.set(String(name), callback);
        return () => callbacks.delete(String(name));
      },
    };
    installPageSchemaRuntime(
      {
        registry: createPageSchemaRegistry({
          'Users/Index': { fields: { title: { parse: (value) => String(value).toUpperCase() } } },
        }),
        mode: 'throw',
      },
      router,
    );
    callbacks.get('prefetched')?.({ detail: { response } });

    expect(JSON.parse(response.data).props.title).toBe('USERS');
    // Keep the standalone runtime referenced so this test also guards the
    // pure API used by SSR adapters.
    expect(
      (runtime.processPage(page('Users/Index', { title: 'users' }), 'ssr') as PageLike).props,
    ).toHaveProperty('title', 'USERS');
  });

  it('classifies v3 instant visits by component and processes clientVisit pages', () => {
    const failures: SchemaFailure[] = [];
    const callbacks = new Map<string, (event: unknown) => unknown>();
    const router: InertiaRouterLike = {
      init: () => undefined,
      on: (name, callback) => {
        callbacks.set(String(name), callback);
        return () => callbacks.delete(String(name));
      },
    };

    installPageSchemaRuntime(
      {
        registry: createPageSchemaRegistry({
          Users: { fields: { id: { parse: (value) => Number(value) } } },
        }),
        mode: 'report',
        onFailure: (failure) => failures.push(failure),
      },
      router,
    );

    callbacks.get('start')?.({
      detail: { visit: { component: 'Users', only: [], except: [], reset: [] } },
    });

    const clientPage = page('Users', { id: '42' });
    callbacks.get('clientVisit')?.({ detail: { page: clientPage, visitId: 'visit-1' } });

    expect(clientPage.props).toEqual({ id: 42 });
    expect(failures).toEqual([]);
  });

  it('classifies reset-only v3 reloads as partial', () => {
    const failures: SchemaFailure[] = [];
    const callbacks = new Map<string, (event: unknown) => unknown>();
    const router: InertiaRouterLike = {
      init: () => undefined,
      on: (name, callback) => {
        callbacks.set(String(name), callback);
        return () => callbacks.delete(String(name));
      },
    };

    installPageSchemaRuntime(
      {
        registry: createPageSchemaRegistry({
          Users: { fields: { id: { validate: () => false } } },
        }),
        mode: 'report',
        onFailure: (failure) => failures.push(failure),
      },
      router,
    );

    callbacks.get('start')?.({
      detail: { visit: { component: null, only: [], except: [], reset: ['id'] } },
    });
    callbacks.get('beforeUpdate')?.({ detail: { page: page('Users', { id: 'bad' }) } });

    expect(failures).toHaveLength(1);
    expect(failures[0].phase).toBe('partial');
  });
});
