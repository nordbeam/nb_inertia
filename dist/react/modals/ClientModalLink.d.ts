import { ModalLinkProps } from './ModalLink';
/**
 * Props for ClientModalLink
 */
export type ClientModalLinkProps = Omit<ModalLinkProps, 'children'> & {
    children: React.ReactNode;
};
/**
 * SSR-safe modal link component
 *
 * Renders a regular Inertia Link during SSR and hydration,
 * then switches to ModalLink on the client after mount.
 * This prevents SSR errors from useModalStack context.
 */
export declare function ClientModalLink({ children, ...modalLinkProps }: ClientModalLinkProps): import("react").JSX.Element;
export default ClientModalLink;
//# sourceMappingURL=ClientModalLink.d.ts.map