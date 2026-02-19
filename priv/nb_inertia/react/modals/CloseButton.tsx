/**
 * CloseButton - Accessible close button for modals
 *
 * Renders an X icon button with configurable position, size, and styling.
 *
 * @example
 * ```tsx
 * <CloseButton onClick={close} />
 * <CloseButton onClick={close} position="top-left" size="lg" />
 * ```
 */

import React from 'react';

const POSITION_CLASSES = {
  'top-right': 'absolute top-4 right-4',
  'top-left': 'absolute top-4 left-4',
  custom: '',
} as const;

const SIZE_CLASSES = {
  sm: 'h-4 w-4',
  md: 'h-6 w-6',
  lg: 'h-8 w-8',
} as const;

export interface CloseButtonProps {
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

export const CloseButton: React.FC<CloseButtonProps> = ({
  onClick,
  position = 'top-right',
  size = 'md',
  colorClasses = 'text-gray-400 hover:text-gray-600',
  ariaLabel = 'Close',
  className = '',
}) => {
  const classes = [
    POSITION_CLASSES[position],
    colorClasses,
    'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500',
    'rounded transition-colors',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button type="button" className={classes} aria-label={ariaLabel} onClick={onClick}>
      <svg
        className={SIZE_CLASSES[size]}
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>
  );
};

export default CloseButton;
