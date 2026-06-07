# Color System

This repository uses a warm, high-contrast Paper-based color system across the
terminal, editor, prompt, tmux, and CLI tools.

The goal is to keep one small set of stable color decisions that can be reused
whenever a tool needs manual colors.

## Principles

- Prefer strong contrast over soft, low-contrast text.
- Use warm paper surfaces for backgrounds and UI chrome.
- Keep normal text black unless there is a specific semantic reason not to.
- Use muted accents for syntax and tool identity, not broad background areas.
- Use bright colors only for transient state: search, selection, warnings,
  errors, and focused diff regions.
- Keep ANSI colors aligned with the Paper palette.

## Source of Truth

Current color decisions are derived from these files:

- `config/alacritty/alacritty.toml`
- `config/nvim/colors/paper-custom.vim`
- `config/nvim/colors/paper.vim`
- `config/nvim/init.lua`

Related consumers that already follow the same palette:

- `config/tmux/tmux.conf`
- `config/starship.toml`
- `config/shell/aliases.sh`

`paper-custom.vim` is the maintained Neovim colorscheme. `paper.vim` is kept as
the upstream Paper base, and `init.lua` contains fallback overrides for the
legacy `paper` theme only.

## Core Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `paper.canvas` | `#f2eede` | Main background | Alacritty background, Nvim `Normal`, Starship directory, fzf background |
| `paper.float` | `#eee8d5` | Popup and floating surfaces | Nvim `NormalFloat`, `Pmenu` |
| `paper.gutter` | `#e8e1cc` | Editor gutter and current-line surfaces | Nvim line number background, cursor line, sign column |
| `paper.subtle` | `#d8d0b8` | Subtle structural surface | Nvim color column, folds |
| `paper.chrome` | `#c8c3b3` | Inactive chrome | tmux status, Starship user and git branch |
| `paper.chromeActive` | `#b8ad94` | Active chrome and borders | Nvim statusline, tmux current window, fzf border |
| `ink.primary` | `#000000` | Primary text | Default foreground across tools |
| `ink.secondary` | `#303030` | Secondary text | Nvim line numbers and non-text, Starship time |
| `ink.tertiary` | `#555555` | Dim terminal foreground | ANSI bright black |
| `ink.border` | `#777777` | Separators | Nvim window separator |
| `ink.disabled` | `#aaaaaa` | Muted terminal white | ANSI white and bright white |
| `ink.inverse` | `#ffffff` | Text on strong dark backgrounds | Error and danger backgrounds |

## Accent Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `accent.blue` | `#1e6fcc` | Blue ANSI and technical metadata | Alacritty, Paper, Docker prompt segment |
| `accent.green` | `#216609` | Success, strings, Node.js | Alacritty, Paper, Starship |
| `accent.yellow` | `#b58900` | Warning base and Python | Alacritty, Paper, Starship |
| `accent.orange` | `#a55000` | Git state, Rust, macro-like syntax | Paper, Starship |
| `accent.red` | `#cc3e28` | ANSI red and syntax error base | Alacritty, Paper |
| `accent.magenta` | `#5c21a5` | Directories and magenta ANSI | Alacritty, Paper |
| `accent.cyan` | `#158c86` | Cyan ANSI and Kubernetes | Alacritty, Paper, Starship |
| `accent.comment` | `#2f5f8f` | Comments and CLI highlights | Nvim comments, fzf prompt/highlight |
| `accent.commentStrong` | `#254a70` | Strong comments | Nvim special comments |

## State Palette

| Token | Hex | Role | Current usage |
|---|---:|---|---|
| `state.selection` | `#b7c9dc` | Standard selection | Alacritty selection, Nvim visual selection, popup selection, tmux copy mode, fzf selected row |
| `state.search` | `#ffd400` | Search and command messages | Alacritty search, Nvim search, tmux message |
| `state.searchActive` | `#9f3a30` | Active search and strong danger | Nvim incsearch, Starship root/read-only |
| `state.infoFg` | `#3f5f2a` | Informational diagnostic text | Nvim diagnostic info foreground |
| `state.infoBg` | `#d8e4c8` | Informational diagnostic background | Nvim diagnostic float and virtual text |
| `state.warnFg` | `#7a3f00` | Warning diagnostic text | Nvim diagnostic warning foreground |
| `state.warnBg` | `#f2de91` | Warning diagnostic background | Nvim diagnostic float and virtual text |
| `state.errorBg` | `#7f1d1d` | Severe error background | Nvim diagnostic float and virtual text |
| `state.diffAdd` | `#c5d9b8` | Added diff background | Nvim diff add |
| `state.diffChange` | `#ffd866` | Changed diff background | Nvim diff change |
| `state.diffText` | `#ffb454` | Focused changed diff text | Nvim diff text |
| `state.diffDelete` | `#9f3a30` | Deleted diff background | Nvim diff delete |

## ANSI Mapping

Keep terminal ANSI colors close to the upstream Paper palette.

| ANSI | Token | Hex |
|---|---|---:|
| black | `ink.primary` | `#000000` |
| red | `accent.red` | `#cc3e28` |
| green | `accent.green` | `#216609` |
| yellow | `accent.yellow` | `#b58900` |
| blue | `accent.blue` | `#1e6fcc` |
| magenta | `accent.magenta` | `#5c21a5` |
| cyan | `accent.cyan` | `#158c86` |
| white | `ink.disabled` | `#aaaaaa` |
| bright black | `ink.tertiary` | `#555555` |
| bright red | `accent.red` | `#cc3e28` |
| bright green | `accent.green` | `#216609` |
| bright yellow | `accent.yellow` | `#b58900` |
| bright blue | `accent.blue` | `#1e6fcc` |
| bright magenta | `accent.magenta` | `#5c21a5` |
| bright cyan | `accent.cyan` | `#158c86` |
| bright white | `ink.disabled` | `#aaaaaa` |

## Usage Rules

When creating a color configuration for another tool, preserve the semantics
before matching local naming. Prefer existing tool concepts such as foreground,
background, selection, cursor, search, ANSI, status, diagnostic, and diff over
inventing decorative roles.

Keep important text high contrast. Use `ink.primary` for ordinary foregrounds,
reserve lighter grays for metadata or disabled states, and use inverse text only
on strong dark backgrounds.

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
use the nearest ANSI mapping rather than adding new colors.

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

## Alternatives

These colors are intentionally not active system tokens, but are kept as
reviewed alternatives for future tuning.

- `#9fc5e8`: brighter selection blue. It is more immediately visible for
  terminal drag selection, but it is cooler and more assertive than
  `state.selection` (`#b7c9dc`) across Nvim, tmux, and fzf.
