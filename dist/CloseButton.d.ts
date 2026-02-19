import { default as default_2 } from 'react';

declare const CloseButton: default_2.FC<CloseButtonProps>;
export { CloseButton }
export default CloseButton;

export declare interface CloseButtonProps {
    /** Click handler to close the modal */
    onClick: () => void;
    /** Position of the button */
    position?: keyof typeof POSITION_CLASSES;
    /** Size of the icon */
    size?: keyof typeof SIZE_CLASSES;
    /** Custom color classes */
    colorClasses?: string;
    /** Accessible label */
    ariaLabel?: string;
    /** Additional CSS classes */
    className?: string;
}

declare const POSITION_CLASSES: {
    readonly 'top-right': "absolute top-4 right-4";
    readonly 'top-left': "absolute top-4 left-4";
    readonly custom: "";
};

declare const SIZE_CLASSES: {
    readonly sm: "h-4 w-4";
    readonly md: "h-6 w-6";
    readonly lg: "h-8 w-8";
};

export { }
