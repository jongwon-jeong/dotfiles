# AGENTS.md

## Repository Scope

This repository manages personal dotfiles and OS bootstrap scripts.

- Arch Linux + GNOME bootstrap: `scripts/setup_arch_bootstrap.sh`
- Dotfile deployment: `scripts/setup_dotfiles.sh`
- Neovim config: `config/nvim/init.lua`

## Audience

- This is a personal-use repository maintained for one user.
- Keep `README.md` intentionally minimal; do not update it unless explicitly requested.

## Repository Inspection

- Treat hidden dotfiles and dot directories as in scope during repository inspection, excluding `.git/`.
- Treat dotfiles and configuration files as first-class repository content.

## Ignore

- Do not read, summarize, modify, or use files under `.agent-ignore/` unless the user explicitly asks for them by path.

## Editing Rules

- Setup is run manually from the relevant script.
- Keep Arch Linux + GNOME distro bootstrap behavior in `scripts/setup_arch_bootstrap.sh`.
- Keep dotfile deployment behavior centralized in `scripts/setup_dotfiles.sh`.
- Preserve user-owned changes and do not revert unrelated edits.
- Prefer small, explicit changes that match the existing style.
- Prefer editing existing files over creating new helpers.
- Avoid broad refactors, generated churn, and style-only rewrites.
- If you intentionally deviate from local conventions or repo defaults, add a short comment explaining why.

## Comments

- Preserve existing `{{{ / }}}` fold markers in long configuration and script files.
- For large folded sections, name closing markers when it improves navigation.
- Keep ordinary function closing markers simple unless a name materially improves readability.

## Neovim

- Keep Neovim configuration as a single-file SSOT in `config/nvim/init.lua`.
- Preserve the existing `{{{ / }}}` fold structure.
- Do not split the Neovim config into modules unless explicitly requested.

## Linux Bootstrap Path

- Arch Linux + GNOME is the maintained Linux bootstrap path in this repo.
- Unsupported Linux distributions may receive dotfile symlinks, but should not get distro-specific package or desktop setup without an explicit request.
- Do not execute bootstrap or upgrade scripts unless explicitly requested; reading them and running non-mutating syntax/static checks is allowed.

## Preferences

- Prefer practical defaults over maximal customization.
- Prefer stock OS capability, then distro package, then small upstream install.
- When changing bootstrap or system setup behavior, first decide whether the behavior is OS-owned or user-owned.
- For OS-owned behavior, prefer the target platform's native tools, services, packages, and desktop conventions after inspecting the current script and, when needed, checking current upstream documentation.
- For user-owned development workflows, prefer portable, distro-neutral behavior when practical, and isolate unavoidable distro-specific handling behind the relevant bootstrap script.
- Do not hard-code cross-distro assumptions just because they worked on another supported platform; re-evaluate package names, service names, desktop integration, and lifecycle behavior for the target OS.
- Prefer good readability and strong contrast over softer, trendier visuals.

## Remote Development

- Consider SSH/tmux-based remote development when changing shell, tmux, and Neovim behavior.
- Keep shared shell startup and alias files portable across Linux and macOS unless a file is intentionally platform-specific.
- Avoid local-desktop assumptions in shared CLI startup files; gate desktop-only behavior behind environment checks.
- Prefer graceful fallback when clipboard, GUI, network, package-manager, or language-server tools are unavailable on remote servers.
- Keep shell startup fast and quiet for large monorepos and network filesystems.

## Output Style

- Do not use emoji in code, documentation, commits, or runtime output.
- For application, CI, test, and structured logs, use the project's logging framework and standard log levels such as `DEBUG`, `INFO`, `WARN`, and `ERROR`.
- For interactive scripts, prefer plain text status labels such as `INFO`, `WARN`, `ERROR`, and `DONE`.

## Verification

- Run syntax checks for changed shell or zsh files, such as `bash -n` for bash scripts and `zsh -n` for zsh files.
- For shell scripts, prefer `shellcheck` and `shfmt -d` when available.
- For Neovim config changes, run a headless load check when practical.

## Git Workflow

- Review `git status` and `git diff` before committing.
- Run the relevant verification commands before committing.
- Prefer one commit per clear intent.
- Use Conventional Commits: `type: summary`.
- Prefer `feat`, `fix`, `docs`, `refactor`, or `chore`.
- Keep commit subjects concise, focused, and lowercase after the colon.
- Do not mix unrelated changes in one commit.
- Keep commits focused on reviewed working-tree changes only.
