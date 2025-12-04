/**
 * Modal Stack Renderer - Renders modals from the stack using shadcn/ui components
 *
 * This component is copied to your codebase by the nb_inertia installer.
 * Feel free to customize the styling, animations, and behavior to match your app.
 *
 * Prerequisites:
 *   npx shadcn@latest add dialog sheet
 *
 * This component uses:
 * - Dialog (for centered modals)
 * - Sheet (for slideovers)
 * - @radix-ui/react-visually-hidden (for accessibility)
 *
 * Install the accessibility helper:
 *   npm install @radix-ui/react-visually-hidden
 */

import { Suspense, useState, useCallback } from 'react';
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetDescription,
} from '@/components/ui/sheet';
import { useModalStack, ModalPageProvider } from '@nordbeam/nb-inertia/react/modals';
import type { ModalConfig, ModalInstance } from '@nordbeam/nb-inertia/react/modals';
import { VisuallyHidden } from '@radix-ui/react-visually-hidden';

// Animation duration in ms (should match CSS transitions)
const ANIMATION_DURATION = 200;

/**
 * Get Dialog content width class based on size config
 *
 * Customize these to match your design system.
 */
function getDialogSizeClass(size: ModalConfig['size']): string {
  switch (size) {
    case 'sm':
      return 'sm:max-w-sm';
    case 'md':
      return 'sm:max-w-md';
    case 'lg':
      return 'sm:max-w-lg';
    case 'xl':
      return 'sm:max-w-xl';
    case '2xl':
      return 'sm:max-w-2xl';
    case '3xl':
      return 'sm:max-w-3xl';
    case '4xl':
      return 'sm:max-w-4xl';
    case '5xl':
      return 'sm:max-w-5xl';
    case 'full':
      return 'sm:max-w-full';
    default:
      return 'sm:max-w-lg';
  }
}

/**
 * Get Sheet side based on position config
 *
 * Maps position to Sheet side prop.
 */
function getSheetSide(position: ModalConfig['position']): 'top' | 'right' | 'bottom' | 'left' {
  switch (position) {
    case 'left':
      return 'left';
    case 'right':
      return 'right';
    case 'top':
      return 'top';
    case 'bottom':
      return 'bottom';
    default:
      return 'right';
  }
}

/**
 * Default loading spinner component
 *
 * Customize this to match your app's loading state design.
 */
function DefaultLoadingFallback() {
  return (
    <div className="p-6 flex items-center justify-center min-h-[200px]">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>
  );
}

/**
 * Individual modal wrapper that handles animated closing
 */
function AnimatedModal({
  modal,
  onClose,
}: {
  modal: ModalInstance;
  onClose: (id: string) => void;
}) {
  const [isOpen, setIsOpen] = useState(true);
  const isSlideover = modal.config.slideover === true;
  const showCloseButton = modal.config.closeButton !== false;
  const closeExplicitly = modal.config.closeExplicitly === true;
  const Component = modal.component;

  const handleClose = useCallback(() => {
    if (closeExplicitly) return;

    // Trigger close animation
    setIsOpen(false);

    // Call onClose callback immediately for URL update
    if (modal.onClose) {
      modal.onClose();
    }

    // Remove from stack after animation completes
    setTimeout(() => {
      onClose(modal.id);
    }, ANIMATION_DURATION);
  }, [modal.id, modal.onClose, onClose, closeExplicitly]);

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      handleClose();
    }
  };

  // Render loading state or actual content
  const LoadingComponent = modal.loadingComponent;
  const content = (
    <ModalPageProvider
      component={modal.componentName}
      props={modal.props}
      url={modal.url}
    >
      {modal.loading ? (
        // Show loading state - custom component or default spinner
        LoadingComponent ? (
          <LoadingComponent />
        ) : (
          <DefaultLoadingFallback />
        )
      ) : (
        // Show actual content with Suspense for lazy loading
        // Pass handleClose as onClose prop so modal content can trigger close
        <Suspense fallback={<DefaultLoadingFallback />}>
          <Component {...modal.props} onClose={handleClose} />
        </Suspense>
      )}
    </ModalPageProvider>
  );

  if (isSlideover) {
    const side = getSheetSide(modal.config.position);

    return (
      <Sheet open={isOpen} onOpenChange={handleOpenChange}>
        <SheetContent
          side={side}
          // @ts-expect-error - showCloseButton may not be in Sheet type but works
          showCloseButton={showCloseButton}
          className="overflow-y-auto p-0"
          onInteractOutside={(e) => {
            if (closeExplicitly) {
              e.preventDefault();
            }
          }}
          onEscapeKeyDown={(e) => {
            if (closeExplicitly) {
              e.preventDefault();
            }
          }}
        >
          <VisuallyHidden>
            <SheetTitle>Modal</SheetTitle>
            <SheetDescription>Modal content</SheetDescription>
          </VisuallyHidden>
          {content}
        </SheetContent>
      </Sheet>
    );
  }

  const sizeClass = getDialogSizeClass(modal.config.size);

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent
        className={`overflow-y-auto max-h-[90vh] ${sizeClass}`}
        // @ts-expect-error - showCloseButton may not be in Dialog type but works
        showCloseButton={showCloseButton}
        onInteractOutside={(e) => {
          if (closeExplicitly) {
            e.preventDefault();
          }
        }}
        onEscapeKeyDown={(e) => {
          if (closeExplicitly) {
            e.preventDefault();
          }
        }}
      >
        <VisuallyHidden>
          <DialogTitle>Modal</DialogTitle>
          <DialogDescription>Modal content</DialogDescription>
        </VisuallyHidden>
        {content}
      </DialogContent>
    </Dialog>
  );
}

/**
 * Modal Stack Renderer
 *
 * Renders all modals in the stack using shadcn/ui Dialog and Sheet components.
 *
 * Usage:
 *   Add this component once in your app layout:
 *
 *   ```tsx
 *   import { ModalStackProvider, InitialModalHandler } from '@nordbeam/nb-inertia/react/modals';
 *   import { ModalStackRenderer } from '@/components/modals/ModalStackRenderer';
 *
 *   function App({ children }) {
 *     return (
 *       <ModalStackProvider resolveComponent={resolvePageComponent}>
 *         <InitialModalHandler resolveComponent={resolvePageComponent} />
 *         {children}
 *         <ModalStackRenderer />
 *       </ModalStackProvider>
 *     );
 *   }
 *   ```
 *
 * Customization:
 *   - Modify getDialogSizeClass() to change modal sizes
 *   - Modify DefaultLoadingFallback() to change loading state
 *   - Adjust ANIMATION_DURATION to match your CSS transitions
 *   - Add additional styling via className props
 */
export function ModalStackRenderer() {
  const { modals, popModal } = useModalStack();

  return (
    <>
      {modals.map((modal) => (
        <AnimatedModal key={modal.id} modal={modal} onClose={popModal} />
      ))}
    </>
  );
}

export default ModalStackRenderer;
