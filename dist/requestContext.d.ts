export declare function getCurrentModalRequestContext(): ModalRequestContext | null;

declare type HeaderOptions = {
    headers?: Record<string, string>;
};

export declare function mergeModalHeaders<TOptions extends HeaderOptions | undefined>(options: TOptions, context?: ModalRequestContext | null): TOptions;

export declare interface ModalRequestContext {
    url: string;
    baseUrl?: string;
    returnUrl?: string;
}

export declare function registerModalRequestContext(id: symbol, context: ModalRequestContext): void;

export declare function resolveModalBaseUrl(context?: ModalRequestContext | null): string | undefined;

export declare function unregisterModalRequestContext(id: symbol): void;

export { }
