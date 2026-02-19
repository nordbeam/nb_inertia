/**
 * ModalRenderer - Renders the modal stack with backdrop and proper z-indexing
 *
 * This component renders all open modals from the stack. Each modal gets:
 * - A backdrop overlay
 * - Proper z-indexing based on stack position
 * - Page context for usePage() to work inside modals
 * - Close button (configurable)
 *
 * The component is intentionally unstyled beyond z-indexing. Users should
 * style their modal components or use the provided utility classes.
 *
 * @example
 * ```tsx
 * import { ModalStackProvider, InitialModalHandler, ModalRenderer } from '@nordbeam/nb-inertia/react/modals';
 *
 * function App({ Component, props }) {
 *   return (
 *     <ModalStackProvider>
 *       <Component {...props} />
 *       <InitialModalHandler resolveComponent={resolveComponent} />
 *       <ModalRenderer />
 *     </ModalStackProvider>
 *   );
 * }
 * ```
 *
 * @example Custom rendering
 * ```tsx
 * <ModalRenderer
 *   renderModal={({ modal, close, config, zIndex }) => (
 *     <MyCustomModalShell config={config} zIndex={zIndex} onClose={close}>
 *       <modal.component {...modal.props} close={close} />
 *     </MyCustomModalShell>
 *   )}
 * />
 * ```
 */

import React from 'react';
import { useModalStack, ModalPageProvider } from './modalStack';
import { HeadlessModal } from './HeadlessModal';
import { CloseButton } from './CloseButton';
import type { ModalInstance, ModalConfig } from './types';
import { mergeModalConfig } from './types';

const BASE_Z_INDEX = 50;

function getZIndex(index: number): number {
  return BASE_Z_INDEX + index * 2;
}

export interface ModalRenderContext {
  /** The modal instance */
  modal: ModalInstance;
  /** Function to close this modal */
  close: () => void;
  /** Merged modal config with defaults */
  config: ModalConfig;
  /** Computed z-index for this modal */
  zIndex: number;
  /** Index in the stack (0-based) */
  index: number;
}

export interface ModalRendererProps {
  /**
   * Custom render function for each modal.
   * If not provided, uses a default rendering with backdrop and basic shell.
   */
  renderModal?: (context: ModalRenderContext) => React.ReactNode;

  /**
   * CSS classes for the backdrop overlay.
   * @default 'fixed inset-0 bg-black/50'
   */
  backdropClassName?: string;

  /**
   * CSS classes for the modal content wrapper.
   * @default 'fixed inset-0 flex items-center justify-center'
   */
  wrapperClassName?: string;
}

/**
 * Default modal rendering with backdrop and centered content
 */
function DefaultModalRenderer({
  modal,
  close,
  config,
  zIndex,
  backdropClassName,
  wrapperClassName,
}: ModalRenderContext & { backdropClassName: string; wrapperClassName: string }) {
  const Component = modal.component;
  const showCloseButton = config.closeButton !== false;

  if (modal.loading) {
    const LoadingComponent = modal.loadingComponent;
    return (
      <>
        <div
          className={backdropClassName}
          style={{ zIndex }}
          onClick={config.closeExplicitly ? undefined : close}
          aria-hidden="true"
        />
        <div className={wrapperClassName} style={{ zIndex: zIndex + 1 }}>
          <div className="relative">
            {showCloseButton && <CloseButton onClick={close} />}
            {LoadingComponent ? <LoadingComponent /> : null}
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <div
        className={backdropClassName}
        style={{ zIndex }}
        onClick={config.closeExplicitly ? undefined : close}
        aria-hidden="true"
      />
      <div
        className={wrapperClassName}
        style={{ zIndex: zIndex + 1 }}
        role="dialog"
        aria-modal="true"
      >
        <div className="relative">
          {showCloseButton && <CloseButton onClick={close} />}
          <Component {...modal.props} close={close} />
        </div>
      </div>
    </>
  );
}

export const ModalRenderer: React.FC<ModalRendererProps> = ({
  renderModal,
  backdropClassName = 'fixed inset-0 bg-black/50',
  wrapperClassName = 'fixed inset-0 flex items-center justify-center',
}) => {
  const { modals, popModal } = useModalStack();

  if (modals.length === 0) return null;

  return (
    <>
      {modals.map((modal, index) => {
        const zIndex = getZIndex(index);
        const config = mergeModalConfig(modal.config);
        const close = () => popModal(modal.id);

        const context: ModalRenderContext = {
          modal,
          close,
          config,
          zIndex,
          index,
        };

        return (
          <ModalPageProvider
            key={modal.id}
            component={modal.componentName}
            props={modal.props}
            url={modal.url}
          >
            <HeadlessModal modal={modal} onClose={close}>
              {() =>
                renderModal ? (
                  renderModal(context)
                ) : (
                  <DefaultModalRenderer
                    {...context}
                    backdropClassName={config.backdropClasses ? `${backdropClassName} ${config.backdropClasses}` : backdropClassName}
                    wrapperClassName={wrapperClassName}
                  />
                )
              }
            </HeadlessModal>
          </ModalPageProvider>
        );
      })}
    </>
  );
};

export default ModalRenderer;
