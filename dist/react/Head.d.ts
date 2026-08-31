import { default as React } from 'react';
import { Head as InertiaHead } from '@inertiajs/react';
/**
 * Props for the Head component (matches Inertia's HeadProps)
 */
export type HeadProps = React.ComponentProps<typeof InertiaHead>;
/**
 * Enhanced Head component
 *
 * Delegate to Inertia's head manager in every context. Modal content is
 * rendered below the application's Inertia provider, so using the official
 * component preserves title callbacks, server-head handling, head keys, and
 * child elements such as meta/link/script tags.
 *
 * @param props - Head props (title and optional children)
 */
export declare const Head: React.FC<HeadProps>;
export default Head;
//# sourceMappingURL=Head.d.ts.map