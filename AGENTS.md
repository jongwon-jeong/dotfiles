# AGENTS.md

## Repository Scope

This repository manages personal dotfiles and OS bootstrap scripts.

- Arch Linux + Sway/Wayland bootstrap: `scripts/setup_arch_bootstrap.sh`
- Dotfile deployment: `scripts/setup_dotfiles.sh`
- Neovim config: `config/nvim/init.lua`

## Audience

- This is a personal-use repository maintained for one user.
- Assume the maintainer already has access to the repository. Do not add clone instructions, contributor onboarding, or multi-user abstractions unless explicitly requested.
- Keep `README.md` focused on installation and bootstrap. Keep desktop operation and keybinding workflows in `docs/sway-workflow.md`; do not update README unless explicitly requested.
- If a requested behavior change would make `README.md` inaccurate and README editing was not explicitly requested, leave it unchanged and report the exact stale section, changed behavior, and required follow-up.

## Policy Files

- `AGENTS.md` governs this repository.
- `home/.codex/AGENTS.md` is deployed as global Codex policy.
- Change either file only when the user explicitly requests the corresponding repository or global policy change.
- Do not edit policy files incidentally during ordinary dotfile, bootstrap, or documentation work.
- After an authorized policy change, review the complete policy diff for weakened constraints, conflicting authority, and broader permissions.

## Platform Support

- Arch Linux + Sway on Wayland is the fully maintained desktop and bootstrap target.
- The maintained Sway configuration must support both desktop and laptop hardware. Keep shared behavior independent of fixed output names, PCI addresses, batteries, backlights, and lid switches; isolate unavoidable machine-specific output profiles.
- Arch Linux on WSL supports the explicitly gated CLI subset; do not assume desktop services, systemd integration, or Linux GUI clipboard tools are available.
- macOS supports dotfile deployment and shared user-owned shell workflows, but has no OS bootstrap path in this repo.
- Other Linux distributions may receive portable dotfile symlinks only; do not add package-manager, service, or desktop behavior for them without an explicit request.
- Treat Windows Terminal configuration as a user-applied asset, not as a Windows bootstrap path.

## Repository Inspection

- Treat hidden dotfiles and dot directories as in scope during repository inspection, excluding `.git/`.
- Treat dotfiles and configuration files as first-class repository content.

## Ignore

- Do not read, summarize, modify, or use files under `.agent-ignore/` unless the user explicitly asks for them by path.

## Editing Rules

- Treat analysis, diagnosis, review, and improvement proposals as read-only unless the user explicitly requests changes.
- Setup is run manually from the relevant script.
- Do not execute `scripts/setup_dotfiles.sh`, bootstrap scripts, or upgrade commands unless explicitly requested. Non-mutating inspection and static checks are allowed.
- Keep Arch Linux + Sway distro bootstrap behavior in `scripts/setup_arch_bootstrap.sh`.
- Keep dotfile deployment behavior centralized in `scripts/setup_dotfiles.sh`.
- Preserve user-owned changes and do not revert unrelated edits.
- Prefer small, explicit changes that match the existing style.
- Prefer editing existing files over creating new helpers.
- Avoid broad refactors, generated churn, and style-only rewrites.
- If you intentionally deviate from local conventions or repo defaults, add a short comment explaining why.

## User Decision Boundaries

- Require an explicit user decision before materially changing maintained platform support, boot or disk policy, login or authentication, firewall or network privacy, destructive data lifecycle behavior, or another boundary already reserved to the user in this file.
- Require an explicit user decision before changing automatic low-battery thresholds or their resulting suspend, hibernate, or power-off behavior. Automatic low-battery power-off must use system-scoped batteries, provide a visible grace period, re-check the trigger immediately before acting, cancel when the trigger clears, and remain inert when system battery hardware is absent.
- Do not add or remove OS packages, persistent system services, or long-running user services unless the requested capability clearly requires the change. When it does, report the owner, lifecycle, network and data impact, hardware behavior, and practical alternative.

## Deployment Ownership

- Treat the checked-out repository as the canonical source. When `scripts/setup_dotfiles.sh` runs from another path, `~/.dotfiles` is a derived deployment copy and home/config entries are symlinks into that copy.
- Keep dotfile deployment deliberately simple: replace the derived `~/.dotfiles` copy as a whole during each manual deployment, preserve the previous copy in the run-specific timestamped backup, and leave recovery to an explicit manual decision. Do not add manifests, staging, automatic pruning, or automatic rollback unless explicitly requested.
- Treat files under `config/system/` as canonical source material for the owning bootstrap task. Files installed into `/etc`, `/usr/local/bin`, or `/usr/local/share` are derived system state, not independent sources to edit in place.
- Update canonical repository files and redeploy through the owning script. When `~/.dotfiles` is a derived deployment copy rather than the checkout itself, direct edits there do not complete a repository change and may be replaced on the next deployment; the same applies to deployed home symlinks and installed system copies.
- Keep machine-owned state outside the shared deployment source. `~/.config/kanshi/local.conf` is the intentional output-profile exception and must survive replacement of `~/.dotfiles`.
- Keep employer-specific identities, SSH hosts, VPN profiles, certificates, and managed security-client state machine-owned and outside the shared deployment source.
- Distinguish `repository changed`, `deployed`, and `runtime verified` in completion reports. Do not imply that a committed configuration is active on a machine without deployment evidence.

## Shell Code

- Follow the global shell naming, scoping, quoting, and command-construction rules.
- Keep files sourced by both interactive shells, such as shared aliases, compatible with Bash and Zsh and use `[[ ... ]]` for their conditionals. This compatibility requirement does not apply to executable scripts, which must follow their declared shebang. Do not source shared Bash/Zsh files from POSIX `sh`.
- Keep nested functions limited to helpers that are meaningful only during one parent operation; otherwise prefer an ordinary file-level helper.

## Failure Handling

- Do not add blanket `set -e` behavior to the setup scripts; failures are classified and handled at the owning task boundary.
- Exit immediately for invalid invocation, unsupported platform, unsafe privilege context, or a missing prerequisite that prevents meaningful progress.
- Return nonzero for a required operation that did not complete. Callers must either stop, propagate the failure, or explicitly classify it as best-effort.
- For optional tools and integrations, emit `WARN`, preserve usable state, and continue when the remaining setup is still meaningful.
- Ignore an exit status with `|| true` only when that failure is expected and the surrounding code or comment makes the reason clear.
- Keep diagnostic commands read-only, and do not suppress their errors when the output is needed to decide a state-changing action.

## Comments

- Preserve existing `{{{ / }}}` fold markers in long configuration and script files.
- For large folded sections, name closing markers when it improves navigation.
- Keep ordinary function closing markers simple unless a name materially improves readability.

## Neovim

- Keep Neovim configuration as a single-file SSOT in `config/nvim/init.lua`.
- Preserve the existing `{{{ / }}}` fold structure.
- Do not split the Neovim config into modules unless explicitly requested.

## Sway

- Keep the shared Sway compositor configuration in `config/sway/config` as its SSOT.
- Prefer native Wayland paths for maintained desktop applications and services. Keep XWayland as a compatibility boundary for applications that still require X11.
- Manage session services with clear Sway/systemd user-session ownership so reloads do not create duplicate processes and logout does not leave desktop services running.
- Keep user-facing key bindings synchronized with the Sway workflow documentation.
- Do not encode machine-specific output identifiers in the shared Sway config. Put reviewed per-machine output layouts in the dedicated output-profile configuration.

## Desktop Philosophy

- Keep recurring desktop network activity opt-in and user-initiated. Do not enable telemetry, analytics, crash uploads, automatic update polling, geolocation, cloud synchronization, or similar background requests unless explicitly requested or required for requested functionality.
- When recurring outbound access is justified, document its purpose, transmitted data, cadence, and disable path. Prefer established manual update and maintenance workflows over duplicate background checkers.
- Preserve the reviewed firewall and network privacy policy unless the user explicitly requests a change or a demonstrated critical security or operability issue requires one.
- Minimize persistent desktop metadata. Before adding history, cache, or state, identify what is stored, where it is stored, how long it is retained, and how it is cleared; prefer session-scoped state when persistence provides no clear benefit.
- Do not automatically delete user data, trash, browser state, credentials, or broad development caches without an explicit request.
- Prefer a quiet, non-interrupting desktop: keep audible and visual bells and automatic notification banners disabled by default. Retain passive status indicators and user-invoked controls where useful, and interrupt only for an explicit workflow or safety requirement.
- Keep always-visible desktop surfaces privacy-minimal. Show operational state without SSIDs, network addresses, device aliases, or page, document, and window titles when user-invoked detail provides the same function.
- Use the Paper palette as the default surface for maintained desktop UI. Prefer clear borders over introducing white cards solely for separation, and reserve solid accent fills for selection, focus, urgency, and other meaningful states.
- Keep routine interface text at normal weight with compact, sufficient padding. Improve readability first through strong foreground contrast, readable sizing, and removal of visual effects; use bold text or extra spacing only for semantic emphasis or interaction needs.
- Do not add a package or long-running service when an established manual workflow adequately covers the need. For each new daemon, identify its owner, lifecycle, network activity, persistent data, and desktop/laptop behavior.
- Protect occasional long-running tasks with a user-invoked, command-scoped inhibitor instead of weakening the baseline lock or suspend policy globally.
- Do not maintain parallel desktop-environment implementations after a replacement is verified. Treat coexistence as a temporary migration state and remove the superseded implementation once the replacement is complete.

## Desktop Configuration Ownership

- Trace each setting to the component that actually consumes it; successful configuration writes alone do not prove that the maintained desktop behavior changed.
- Ensure commands launched by Sway, systemd user units, desktop entries, and MIME handlers resolve from the non-interactive graphical session environment. Do not treat availability in an interactive shell as proof; when a user tool manager owns a command, expose its supported executable path or shims to the session deliberately.
- Treat GSettings schema availability as insufficient evidence that a setting affects Sway. Use GLib or GTK settings for applications that consume them, and use Sway, systemd-logind, swayidle, or the relevant native owner for compositor, input, power, and session behavior.
- Do not retain GNOME-specific configuration merely because its schemas remain installed. Translate desired behavior to the maintained Sway/Wayland stack or document why a compatibility setting is still required.

## Preferences

- Prefer practical defaults over maximal customization.
- Prefer stock OS capability, then distro package, then small upstream install.
- When changing bootstrap or system setup behavior, first decide whether the behavior is OS-owned or user-owned.
- For OS-owned behavior, prefer the target platform's native tools, services, packages, and desktop conventions after inspecting the current script and, when needed, checking current upstream documentation.
- For user-owned development workflows, prefer portable, distro-neutral behavior when practical, and isolate unavoidable distro-specific handling behind the relevant bootstrap script.
- Do not hard-code cross-distro assumptions just because they worked on another supported platform; re-evaluate package names, service names, desktop integration, and lifecycle behavior for the target OS.
- Prefer good readability and strong contrast over softer, trendier visuals.

## Version Policy

- Prefer current upstream releases for user-owned development tools and Neovim plugins over exact bootstrap reproducibility.
- Prefer distro-managed versions for OS-owned packages, drivers, services, and desktop components.
- Pin a version or revision when an upstream regression, compatibility boundary, or reviewed operational constraint requires it; add a concise comment stating why and when the pin can be reconsidered.
- Do not introduce lockfiles, generated version churn, or broad dependency pinning without a demonstrated need.

## Remote Development

- Consider SSH/tmux-based remote development when changing shell, tmux, and Neovim behavior.
- Keep shared shell startup and alias files portable across Linux and macOS unless a file is intentionally platform-specific.
- Avoid local-desktop assumptions in shared CLI startup files; gate desktop-only behavior behind environment checks.
- Prefer graceful fallback when clipboard, GUI, network, package-manager, or language-server tools are unavailable on remote servers.
- Reuse one explicitly owned authentication agent per local session when practical, keep identity lifetimes bounded, and select identities per host or explicit user action.
- Do not bulk-load every private key, enable agent forwarding globally, or discover and terminate authentication agents outside the current workflow's ownership.
- Keep shell startup fast and quiet for large monorepos and network filesystems.

## Professional Use

- Treat employer onboarding, supported-device, security, and project requirements as authoritative over personal defaults. Do not adapt this repository to bypass a required managed device, supported OS, security control, or approved access path.
- Do not add speculative VPN clients, container stacks, credential integrations, or company-specific tooling. Select the exact supported implementation after the employer or project requirement is known.

## Output Style

- Do not use emoji in code, documentation, commits, or runtime output.
- For application, CI, test, and structured logs, use the project's logging framework and standard log levels such as `DEBUG`, `INFO`, `WARN`, and `ERROR`.
- For interactive scripts, prefer plain text status labels such as `INFO`, `WARN`, `ERROR`, and `DONE`.

## Verification

- Treat `.pre-commit-config.yaml` as the canonical hook list.
- Some hooks rewrite files. Scope them to reviewed files when practical and inspect the resulting diff before reporting completion.
- Run syntax checks for changed shell or zsh files, such as `bash -n` for bash scripts and `zsh -n` for zsh files.
- For shell scripts, prefer `shellcheck` and `shfmt -d` when available.
- For Neovim config changes, run a headless load check when practical.
- On an Arch Sway environment, validate `config/sway/config` with `WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -C -c config/sway/config`.
- On a systemd user environment, validate changed units with `systemd-analyze --user --man=no --generators=no verify` and the relevant files under `config/systemd/user/`.
- Validate changed XML configuration with `xmllint --noout` when available.
- Treat deployment and runtime checks as separate from static checks. After an explicitly requested deployment, verify the relevant symlink or installed target against its canonical source and report any target that was not checked.
- Run `git diff --check` for every change.
- Report the exact checks run, checks not run, and any system, desktop, hardware, or reboot-dependent behavior that remains unverified.
- Static checks do not prove that the bootstrap completed on a real system.

## Long-Running Work and Handoff

- For multi-session migrations or hardware-dependent validation, use the owning issue or PR as the persistent handoff location when one exists; do not treat chat-only state as durable evidence.
- If unfinished multi-session work has no durable handoff location, report that gap and ask the user to choose one instead of inventing a new tracking document or silently relying on conversation history.
- Record the branch and commit, machine or environment class, completed gates, skipped or invalid results, remaining risks, and the next user decision. Keep generic acceptance criteria in the maintained documentation instead of copying task history into it.
- Treat the Sway migration checklist in `docs/sway-workflow.md` as acceptance criteria, not as proof that a particular desktop or laptop passed. Store per-machine results in the owning handoff record.

## Git Workflow

- Do not commit, amend, rebase, force-push, or push unless explicitly requested.
- Review `git status` and `git diff` before committing.
- Run the relevant verification commands before committing.
- Prefer one commit per clear intent.
- Use Conventional Commits: `type: summary`.
- Prefer `feat`, `fix`, `docs`, `refactor`, or `chore`.
- Keep commit subjects concise, focused, and lowercase after the colon.
- Do not mix unrelated changes in one commit.
- Keep commits focused on reviewed working-tree changes only.
