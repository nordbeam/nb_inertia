# Editor Support for NbInertia ~TSX/~JSX Sigils

NbInertia provides `~TSX` and `~JSX` sigils for embedding frontend snippets
inside Elixir files. These editor configurations enable syntax highlighting
for the embedded TSX/JSX content.

## Neovim (Tree-sitter)

Copy the injection queries to your Neovim config:

```bash
mkdir -p ~/.config/nvim/after/queries/elixir
cp editor/nvim/queries/elixir/injections.scm ~/.config/nvim/after/queries/elixir/
```

Requires `nvim-treesitter` with `tsx` and `elixir` parsers installed:

```vim
:TSInstall elixir tsx
```

## Helix

Add the injection rules to your Helix languages config:

```bash
cat editor/helix/languages.toml >> ~/.config/helix/languages.toml
```

Requires `tsx` and `elixir` tree-sitter grammars (included by default in Helix).

## Zed

Install the extension from the Zed extension marketplace (coming soon),
or copy the extension directory to your Zed extensions path:

```bash
cp -r editor/zed ~/.config/zed/extensions/nb-inertia
```

## VS Code

Install from the VS Code marketplace (coming soon), or build and install locally:

```bash
cd editor/vscode
npx @vscode/vsce package
code --install-extension nb-inertia-tsx-0.1.0.vsix
```

This provides syntax highlighting for embedded TSX/JSX snippets.
