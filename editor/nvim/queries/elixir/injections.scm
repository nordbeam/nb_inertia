; NbInertia — Tree-sitter injection queries for ~TSX/~JSX sigils
; Copy to: ~/.config/nvim/after/queries/elixir/injections.scm

; Inject TSX into ~TSX sigils in Elixir files
((sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content)
 (#eq? @_sigil_name "TSX")
 (#set! injection.language "tsx")
 (#set! injection.combined))

; Inject JSX into ~JSX sigils
((sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content)
 (#eq? @_sigil_name "JSX")
 (#set! injection.language "jsx")
 (#set! injection.combined))
