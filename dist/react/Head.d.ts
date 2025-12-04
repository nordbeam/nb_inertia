import { default as React } from 'react';
/**
 * Props for the Head component (matches Inertia's HeadProps)
 */
export interface HeadProps {
    title?: string;
    children?: React.ReactNode;
}
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
export declare const Head: React.FC<HeadProps>;
export default Head;
//# sourceMappingURL=Head.d.ts.map