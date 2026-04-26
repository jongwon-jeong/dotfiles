# AGENTS.md

## Repository Scope

This repository manages personal dotfiles and OS bootstrap scripts.

- Main entrypoint: `install.sh`
- Ubuntu bootstrap: `scripts/setup_ubuntu_bootstrap.sh`
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

- Trace installation behavior from `install.sh` before changing setup flow.
- Keep Ubuntu bootstrap behavior in `scripts/setup_ubuntu_bootstrap.sh`.
- Keep dotfile deployment behavior centralized in `scripts/setup_dotfiles.sh`.
- Preserve user-owned changes and do not revert unrelated edits.
- Prefer small, explicit changes that match the existing style.
- Prefer editing existing files over creating new helpers.
- Avoid broad refactors, generated churn, and style-only rewrites.
- If you intentionally deviate from local conventions or repo defaults, add a short comment explaining why.

## Neovim

- Keep Neovim configuration as a single-file SSOT in `config/nvim/init.lua`.
- Preserve the existing `{{{ / }}}` fold structure.
- Do not split the Neovim config into modules unless explicitly requested.

## Ubuntu Path

- Ubuntu is the only maintained Linux bootstrap path in this repo.
- Unsupported Linux distributions may receive dotfile symlinks, but should not get distro-specific package or desktop setup without an explicit request.
- Do not execute bootstrap or upgrade scripts unless explicitly requested; reading them and running non-mutating syntax/static checks is allowed.

## Preferences

- Prefer practical defaults over maximal customization.
- Prefer stock OS capability, then distro package, then small upstream install.
- Prefer good readability and strong contrast over softer, trendier visuals.

## Verification

- Run syntax checks for changed shell or zsh files, such as `bash -n` for bash scripts and `zsh -n` for zsh files.

## Git Workflow

- Do not create commits unless explicitly requested.
- Review `git status` and `git diff` before committing.
- Run the relevant verification commands before committing.
- Prefer one commit per clear intent.
- Use Conventional Commits: `type: summary`.
- Prefer `feat`, `fix`, `docs`, `refactor`, or `chore`.
- Keep commit subjects concise, focused, and lowercase after the colon.
- Do not mix unrelated changes in one commit.
- Keep commits focused on reviewed working-tree changes only.
- Do not amend, rebase, force-push, or rewrite history unless explicitly requested.
