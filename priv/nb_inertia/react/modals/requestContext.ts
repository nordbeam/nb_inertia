export interface ModalRequestContext {
  url: string;
  baseUrl?: string;
  returnUrl?: string;
}

type HeaderOptions = {
  headers?: Record<string, string>;
};

interface ModalRequestContextEntry {
  id: symbol;
  context: ModalRequestContext;
}

const STACK_KEY = '__nb_inertia_modal_request_context_stack';

function getRequestContextStack(): ModalRequestContextEntry[] {
  if (typeof window === 'undefined') {
    return [];
  }

  const existing = (window as typeof window & { [STACK_KEY]?: ModalRequestContextEntry[] })[
    STACK_KEY
  ];

  if (existing) {
    return existing;
  }

  const created: ModalRequestContextEntry[] = [];
  (
    window as typeof window & {
      [STACK_KEY]?: ModalRequestContextEntry[];
    }
  )[STACK_KEY] = created;

  return created;
}

export function registerModalRequestContext(id: symbol, context: ModalRequestContext) {
  if (typeof window === 'undefined') {
    return;
  }

  const stack = getRequestContextStack();
  const existingIndex = stack.findIndex((entry) => entry.id === id);

  if (existingIndex >= 0) {
    stack[existingIndex] = { id, context };
  } else {
    stack.push({ id, context });
  }
}

export function unregisterModalRequestContext(id: symbol) {
  if (typeof window === 'undefined') {
    return;
  }

  const stack = getRequestContextStack();
  const existingIndex = stack.findIndex((entry) => entry.id === id);

  if (existingIndex >= 0) {
    stack.splice(existingIndex, 1);
  }
}

export function getCurrentModalRequestContext(): ModalRequestContext | null {
  const stack = getRequestContextStack();
  const current = stack[stack.length - 1];

  return current?.context ?? null;
}

export function resolveModalBaseUrl(context?: ModalRequestContext | null): string | undefined {
  if (!context) {
    return undefined;
  }

  return context.returnUrl || context.baseUrl || context.url;
}

export function mergeModalHeaders<
  TOptions extends HeaderOptions | undefined,
>(options: TOptions, context?: ModalRequestContext | null): TOptions {
  const baseUrl = resolveModalBaseUrl(context);

  if (!baseUrl) {
    return options as TOptions;
  }

  const merged = {
    ...(options ?? {}),
    headers: {
      ...(options?.headers ?? {}),
      'x-inertia-modal': 'true',
      'x-inertia-modal-base-url': baseUrl,
    },
  };

  return merged as unknown as TOptions;
}
