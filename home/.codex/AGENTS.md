# Global Codex Instructions

## Language

- Explain in Korean by default.
- Write code, commands, commit messages, and config snippets in English. Match the existing language for documentation and prose files.

## Work Style

- Follow repository `AGENTS.md` files. More specific instructions override this file.
- Prefer concise, practical answers with enough context to act correctly.
- Prefer `rg` and `rg --files` for searching text and files.
- Prefer small, focused changes that solve the requested problem.
- Do not rewrite or restate entire files unless explicitly requested.
- When modifying files, show only the relevant changed parts with enough file and location context.

## Comments

- Use comments to explain why code is structured a certain way, including intent, ordering constraints, tradeoffs, or operational risks.
- Avoid comments that merely restate what the code already says.
- Keep comments general enough to remain accurate when implementation details change.
- Prefer concise comments near the code they clarify.

## Git

- Do not commit, amend, rebase, force-push, or push unless explicitly requested.

## Safety

- Do not add or expose real secrets, credentials, tokens, or private keys.
- Do not run destructive, production, credential-related, or system-modifying commands unless explicitly requested.
