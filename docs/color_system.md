# Color System

This repository uses a warm Paper-based color system across the terminal,
editor, prompt, tmux, and CLI tools.

The goal is to keep one small set of stable color decisions that can be reused
whenever a tool needs manual colors.

## Principles

- Prefer strong contrast for primary text and UI states.
- Use warm paper surfaces for backgrounds and UI chrome.
- Keep normal text black unless there is a specific semantic reason not to.
- Use muted accents for syntax and tool identity, not broad background areas.
- Use high-attention colors only for transient state: search, selection, warnings,
  errors, and focused diff regions.
- Keep terminal ANSI colors close to the original Paper accents. When a tool
  needs stronger readability than the shared ANSI palette provides, add a
  tool-specific mapping instead of changing the global palette.

## Source of Truth

Current maintained color decisions are derived from these files:

- `config/alacritty/alacritty.toml`
- `config/windows-terminal/paper-custom.json`
- `config/nvim/colors/paper-custom.vim`
- `config/nvim/init.lua`
- `home/.codex/themes/paper-custom-codex.tmTheme`

Related consumers that already follow the same palette:

- `config/tmux/tmux.conf`
- `config/starship.toml`
- `config/shell/aliases.sh`

`paper-custom.vim` is the maintained Neovim colorscheme. `paper.vim` is kept as
the upstream Paper base rather than a maintained source of current terminal ANSI
decisions, and `init.lua` contains fallback overrides for the legacy `paper`
theme only.

## Core Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `paper.canvas` | `#f2eede` | Main background | Terminal backgrounds, Codex background, Nvim `Normal`, Starship directory, fzf background |
| `paper.float` | `#eee8d5` | Popup and floating surfaces | Nvim `NormalFloat`, `Pmenu` |
| `paper.gutter` | `#e8e1cc` | Editor gutter and current-line surfaces | Nvim line number background, cursor line, sign column |
| `paper.subtle` | `#d8d0b8` | Subtle structural surface | Nvim color column, folds |
| `paper.chrome` | `#c8c3b3` | Inactive chrome | tmux status, Starship user and git branch |
| `paper.chromeActive` | `#b8ad94` | Active chrome and borders | Nvim statusline, tmux current window, fzf border |
| `ink.primary` | `#000000` | Primary text | Default foreground across tools, Codex primary syntax |
| `ink.secondary` | `#303030` | Secondary text | Nvim line numbers and non-text, Starship time |
| `ink.tertiary` | `#555555` | Muted terminal foreground | ANSI bright black |
| `ink.border` | `#777777` | Separators | Nvim window separator |
| `ink.disabled` | `#aaaaaa` | Muted terminal white | ANSI white and bright white |
| `ink.inverse` | `#ffffff` | Text on strong dark backgrounds | Error and danger backgrounds |

## Accent Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `accent.blue` | `#1e6fcc` | Blue ANSI and technical metadata | Terminals, Paper, Codex, Docker prompt segment |
| `accent.green` | `#216609` | Success, strings, Node.js | Paper, Codex, Starship |
| `accent.yellow` | `#b58900` | Warning base and Python | Terminals, Paper, Starship |
| `accent.orange` | `#a55000` | Git state, Rust, macro-like syntax | Paper, Starship |
| `accent.red` | `#cc3e28` | ANSI red and syntax error base | Terminals, Paper |
| `accent.magenta` | `#5c21a5` | Directories and magenta ANSI | Terminals, Paper, Codex |
| `accent.cyan` | `#158c86` | Cyan ANSI and Kubernetes | Terminals, Paper, Codex, Starship |
| `accent.comment` | `#2f5f8f` | Comments and CLI highlights | Nvim comments, Codex comments, fzf prompt/highlight |
| `accent.commentStrong` | `#254a70` | Strong comments | Nvim special comments |

## State Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `state.selection` | `#b7c9dc` | Standard selection | Terminal selection, Codex selection, Nvim visual selection, popup selection, tmux copy mode, fzf selected row |
| `state.search` | `#ffd400` | Search and command messages | Alacritty search, Nvim search, tmux message |
| `state.searchActive` | `#9f3a30` | Active search and strong danger | Nvim incsearch, Starship root/read-only |
| `state.infoFg` | `#3f5f2a` | Informational diagnostic text | Nvim diagnostic info foreground |
| `state.infoBg` | `#d8e4c8` | Informational diagnostic background | Nvim diagnostic float and virtual text |
| `state.warnFg` | `#7a3f00` | Warning diagnostic text | Nvim diagnostic warning foreground |
| `state.warnBg` | `#f2de91` | Warning diagnostic background | Nvim diagnostic float and virtual text |
| `state.errorBg` | `#7f1d1d` | Severe error background | Nvim diagnostic float and virtual text |
| `state.diffAdd` | `#c5d9b8` | Added diff background | Nvim diff add, Codex inserted diff |
| `state.diffChange` | `#ffd866` | Changed diff background | Nvim diff change, Codex changed diff |
| `state.diffText` | `#ffb454` | Focused changed diff text | Nvim diff text |
| `state.diffDelete` | `#9f3a30` | Deleted diff background | Nvim diff delete, Codex deleted diff |

## Terminal ANSI Palette

Terminal ANSI colors intentionally follow the original Paper accent palette.
This keeps terminal output visually consistent with Neovim, Starship, tmux, and
fzf. Some ANSI colors are softer on `paper.canvas`; tools that emit their own
truecolor syntax tokens should map those tokens explicitly instead of relying on
terminal ANSI fallback behavior.

| Token | Hex | Contrast on `paper.canvas` | Role |
|---|---:|---:|---|
| `terminal.black` | `#000000` | 18.06 | ANSI black |
| `terminal.red` | `#cc3e28` | 4.21 | ANSI red |
| `terminal.green` | `#216609` | 6.08 | ANSI green |
| `terminal.yellow` | `#b58900` | 2.76 | ANSI yellow |
| `terminal.blue` | `#1e6fcc` | 4.30 | ANSI blue |
| `terminal.magenta` | `#5c21a5` | 8.15 | ANSI magenta |
| `terminal.cyan` | `#158c86` | 3.52 | ANSI cyan |
| `terminal.white` | `#aaaaaa` | 2.00 | ANSI white |
| `terminal.brightBlack` | `#555555` | 6.41 | ANSI bright black / dim text |
| `terminal.brightRed` | `#cc3e28` | 4.21 | ANSI bright red |
| `terminal.brightGreen` | `#216609` | 6.08 | ANSI bright green |
| `terminal.brightYellow` | `#b58900` | 2.76 | ANSI bright yellow |
| `terminal.brightBlue` | `#1e6fcc` | 4.30 | ANSI bright blue |
| `terminal.brightMagenta` | `#5c21a5` | 8.15 | ANSI bright magenta |
| `terminal.brightCyan` | `#158c86` | 3.52 | ANSI bright cyan |
| `terminal.brightWhite` | `#aaaaaa` | 2.00 | ANSI bright white |

## ANSI Mapping

Map ANSI directly to the terminal palette. Bright colors intentionally stay
close to their normal counterparts, matching the original Paper palette.

| ANSI | Token | Hex |
|---|---|---:|
| black | `terminal.black` | `#000000` |
| red | `terminal.red` | `#cc3e28` |
| green | `terminal.green` | `#216609` |
| yellow | `terminal.yellow` | `#b58900` |
| blue | `terminal.blue` | `#1e6fcc` |
| magenta | `terminal.magenta` | `#5c21a5` |
| cyan | `terminal.cyan` | `#158c86` |
| white | `terminal.white` | `#aaaaaa` |
| bright black | `terminal.brightBlack` | `#555555` |
| bright red | `terminal.brightRed` | `#cc3e28` |
| bright green | `terminal.brightGreen` | `#216609` |
| bright yellow | `terminal.brightYellow` | `#b58900` |
| bright blue | `terminal.brightBlue` | `#1e6fcc` |
| bright magenta | `terminal.brightMagenta` | `#5c21a5` |
| bright cyan | `terminal.brightCyan` | `#158c86` |
| bright white | `terminal.brightWhite` | `#aaaaaa` |

## Usage Rules

When creating a color configuration for another tool, preserve the semantics
before matching local naming. Prefer existing tool concepts such as foreground,
background, selection, cursor, search, ANSI, status, diagnostic, and diff over
inventing decorative roles.

Keep important text high contrast. Use `ink.primary` for ordinary foregrounds,
use `ink.secondary` or `ink.tertiary` for metadata that must stay readable, use
`ink.disabled` only where soft Paper terminal output is acceptable, and use
inverse text only on strong dark backgrounds.

Prefer semantic mappings over ad hoc color choices. If a tool exposes a concept
covered below, use the mapped token even when the tool uses different names.

Avoid broad accent-colored background areas. Accents should identify syntax,
tool state, or transient attention, while warm paper surfaces should carry the
overall UI.

## Implementation Rules

Apply colors in this order when a tool exposes the relevant settings:

1. Set the main background to `paper.canvas` and the main foreground to
   `ink.primary`.
2. Set ANSI colors from the ANSI mapping table without creative substitutions.
   Do not reuse syntax accent tokens for terminal ANSI unless the ANSI table
   explicitly maps to the same value.
3. Set cursor text to `paper.canvas` and cursor body to `ink.primary` when the
   tool supports both.
4. Set selection text to `ink.primary` and selection background to
   `state.selection`.
5. Set search matches to `ink.primary` on `state.search`, and focused search or
   incremental search to `ink.inverse` on `state.searchActive`.
6. Set persistent UI chrome to `paper.chrome`, active chrome to
   `paper.chromeActive`, and separators to `ink.border`.
7. Set editor gutters, sign columns, and cursor-line surfaces to `paper.gutter`.
8. Set floating or popup surfaces to `paper.float`.
9. Set diagnostics and diffs from the semantic mappings below.

Stop after the highest supported step for the target tool, and do not invent
settings for concepts the tool does not expose.

When multiple mappings could apply, prefer the more specific semantic mapping
over the general implementation order.

Use bold only for active or high-attention UI: active status segments, selected
popup rows, search matches, focused diff text, current line numbers, match
paren, warnings, and severe errors. Avoid italics unless the target tool already
requires them for a specific syntax role.

If a tool lacks separate foreground/background controls, keep `ink.primary` and
choose the semantic background token. If a tool only accepts ANSI color names,
use the nearest ANSI mapping rather than adding new colors. Avoid using
background/fill tokens such as `state.selection`, `state.search`, and
`paper.chrome` as foreground colors.

Do not introduce new colors unless explicitly requested. Prefer exact hex tokens
over approximations whenever the target tool supports truecolor.

## Semantic Mappings

### Terminals

Map terminal colors directly:

| Tool concept | Token |
|---|---|
| default background | `paper.canvas` |
| default foreground | `ink.primary` |
| cursor text | `paper.canvas` |
| cursor body | `ink.primary` |
| selection text | `ink.primary` |
| selection background | `state.selection` |
| search match text | `ink.primary` |
| search match background | `state.search` |
| ANSI normal and bright colors | ANSI mapping table |

### Editors

Use these mappings for Neovim, VS Code, JetBrains IDEs, and similar editors:

| Editor concept | Foreground | Background | Style |
|---|---|---|---|
| main editor | `ink.primary` | `paper.canvas` | none |
| floating window or popup | `ink.primary` | `paper.float` | none |
| popup selected row | `ink.primary` | `state.selection` | bold |
| gutter, signs, cursor line | varies | `paper.gutter` | none |
| line numbers | `ink.secondary` | `paper.gutter` | none |
| current line number | `ink.primary` | `paper.chromeActive` | bold |
| color column and folds | `ink.secondary` where needed | `paper.subtle` | folds bold |
| separators | `ink.border` | none | none |
| active statusline | `ink.primary` | `paper.chromeActive` | bold |
| inactive statusline | `ink.primary` | `paper.chrome` | none |
| visual selection | `ink.primary` | `state.selection` | none |
| search match | `ink.primary` | `state.search` | bold |
| focused search match | `ink.inverse` | `state.searchActive` | bold |
| match paren | `ink.primary` | `paper.chromeActive` | bold |
| comments | `accent.comment` | none | none |
| strong comments | `accent.commentStrong` | none | bold |

Keep normal code text black unless syntax semantics require an accent. For Paper
syntax roles, keep strings green, numbers blue, directories and type-like
navigation magenta, macro-like syntax orange, and keywords/operators black.

### Diagnostics

| Diagnostic concept | Foreground | Background | Style |
|---|---|---|---|
| info text or sign | `state.infoFg` | none | none |
| warning text or sign | `state.warnFg` | none | bold |
| error text or sign | `state.errorBg` | none | bold |
| info float or virtual text | `ink.primary` | `state.infoBg` | none |
| warning float or virtual text | `ink.primary` | `state.warnBg` | float bold, virtual text normal |
| error float or virtual text | `ink.inverse` | `state.errorBg` | float bold, virtual text normal |

### Diffs

| Diff concept | Foreground | Background | Style |
|---|---|---|---|
| added lines | `ink.primary` | `state.diffAdd` | none |
| changed lines | `ink.primary` | `state.diffChange` | none |
| deleted lines | `ink.inverse` | `state.diffDelete` | none |
| focused changed text | `ink.primary` | `state.diffText` | bold |

### Prompt, Status, and CLI Tools

Use `paper.chrome` for inactive prompt/status blocks and `paper.chromeActive`
for the active or identity-defining block. Use `ink.primary` for text on both.
Use `ink.secondary` for time, metadata, and unselected items.

Use `state.searchActive` with `ink.inverse` for root, read-only, destructive,
or high-risk states. Use `accent.orange` for git state, `accent.cyan` for
Kubernetes or cluster context, `accent.blue` for Docker or technical metadata,
and `accent.comment` for fuzzy-finder prompts and highlights.

For fuzzy finders, prefer `paper.canvas` as the base background,
`state.selection` for the selected row, `paper.chromeActive` for borders, and
`accent.comment` for prompt, pointer, marker, and match highlights.

For Codex CLI syntax highlighting, keep an explicit Paper mapping in
`home/.codex/themes/paper-custom-codex.tmTheme`. The Codex TUI can emit
truecolor syntax tokens independent of the terminal's ANSI palette, so the
theme must set those tokens directly instead of relying on Windows Terminal,
Alacritty, or Neovim terminal ANSI colors.

## Alternatives

These colors are intentionally not active system tokens, but are kept as
reviewed alternatives for future tuning.

- `#9fc5e8`: brighter selection blue. It is more immediately visible for
  terminal drag selection, but it is cooler and more assertive than
  `state.selection` (`#b7c9dc`) across Nvim, tmux, and fzf.
