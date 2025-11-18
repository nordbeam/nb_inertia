# NbInertia Modal Configuration
#
# This file configures default settings for NbInertia's modal and slideover system.
# These settings provide defaults that can be overridden on a per-modal basis.
#
# For more information, see: https://github.com/nordbeam/nb/tree/main/nb_inertia

import Config

config :nb_inertia, :modal,
  # Default modal size
  # Options: :sm, :md, :lg, :xl, :full, or any custom CSS class string
  # Default: :md
  default_size: :md,

  # Default modal position
  # Options: :center, :top, :bottom, :left, :right, or any custom CSS class string
  # Default: :center
  default_position: :center,

  # Whether to show a close button by default
  # Default: true
  default_close_button: true,

  # Whether modals require explicit close (disable ESC and backdrop click)
  # Default: false
  default_close_explicitly: false,

  # Default custom max-width (CSS value like "800px" or "50rem")
  # Leave nil to use size presets
  # Default: nil
  default_max_width: nil,

  # Default padding classes for modal content
  # Default: "p-6"
  default_padding_classes: "p-6",

  # Default panel classes for the modal container
  # Default: "bg-white rounded-lg shadow-xl"
  default_panel_classes: "bg-white rounded-lg shadow-xl",

  # Default backdrop classes for the overlay
  # Default: "bg-black/50"
  default_backdrop_classes: "bg-black/50"

# Slideover-specific defaults (when slideover: true is used)
config :nb_inertia, :slideover,
  # Default slideover position
  # Options: :right, :left, :top, :bottom
  # Default: :right
  default_position: :right,

  # Default slideover size
  # For horizontal slideovers (:left/:right): width preset or custom class
  # For vertical slideovers (:top/:bottom): height preset or custom class
  # Default: :md
  default_size: :md
