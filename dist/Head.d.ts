import { default as default_2 } from 'react';

/**
 * Enhanced Head component
 *
 * Checks if we're inside a modal context. If so, handles document title
 * updates directly. Otherwise, delegates to Inertia's Head component.
 *
 * In modal context:
 * - Only the `title` prop is supported
 * - The original title is restored when the modal closes
 * - Child elements (meta tags, etc.) are ignored in modal context
 *
 * @param props - Head props (title and optional children)
 */
declare const Head: default_2.FC<HeadProps>;
export { Head }
export default Head;

/**
 * Props for the Head component (matches Inertia's HeadProps)
 */
export declare interface HeadProps {
    title?: string;
    children?: default_2.ReactNode;
}

export { }
