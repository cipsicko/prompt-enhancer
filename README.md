# Prompt Enhancer

A reusable, token-efficient prompt refiner for **Claude Code** and **GitHub Copilot CLI**.

**What it does.** Before you ask an AI anything, you hand it a rough prompt. It asks a few
targeted clarifying questions, then returns a single polished, copy-pasteable prompt — and
stops. It never runs the task itself, so you stay in control of where the final prompt goes.

**Built-in token savings.** The enhancer writes lean prompts (no filler), bakes a "be concise"
constraint into every prompt it produces, and appends a short "to save tokens" tip list
(cheaper model, lower reasoning effort, trim pasted context). The Copilot wrapper also runs the
refiner step at `--effort low` — so both the prompt and the answer it produces cost fewer tokens.

## How you'll use it

| Tool | Command | Example |
|---|---|---|
| Claude Code | `/enhance <rough prompt>` | `/enhance write release notes` |
| Claude Code (skill) | just ask | `make this prompt better: write release notes` |
| Copilot CLI | `enhance <rough prompt>` | `enhance write release notes` |

## Prerequisites

- **Claude Code** installed (for `/enhance` and the skill).
- **GitHub Copilot CLI** installed and authenticated — the `copilot` command on your `PATH`
  (for the `enhance` shell command).
- A **zsh** shell (macOS default). Bash works too — see `--rc` below.

You can install either side on its own — they're independent.

## Install

```bash
git clone https://github.com/cipsicko/prompt-enhancer.git
cd prompt-enhancer
./install.sh
source ~/.zshrc   # or open a new terminal
```

`install.sh` is idempotent — safe to re-run after `git pull`. If it finds an existing file that
differs from the repo copy (i.e. you customized it), it backs it up to `*.bak` first instead of
clobbering it.

Options:

| Flag | Effect |
|---|---|
| `--claude-only` | Shared instructions + slash command + skill; skips your shell rc |
| `--copilot-only` | Shared instructions + `enhance()` shell function only |
| `--rc <path>` | Append the shell function to a specific rc file (default `~/.zshrc`, or `~/.bashrc` when `$SHELL` is bash) |
| `--dry-run` | Print what would change, write nothing |

## What gets installed where

| Repo file | Installed to | Purpose |
|---|---|---|
| `enhance.md` | `~/.config/prompt-enhancer/enhance.md` | **Single source of truth** — all three entry points read it |
| `claude/commands/enhance.md` | `~/.claude/commands/enhance.md` | The `/enhance` slash command |
| `claude/skills/enhance/SKILL.md` | `~/.claude/skills/enhance/SKILL.md` | Skill — lets Claude enhance a prompt on intent, no slash command needed |
| `copilot/enhance.zsh` | appended to `~/.zshrc` | The `enhance` shell function |

### Command vs skill

Both run the same instructions. The **command** is explicit: you type `/enhance …` and it always
fires. The **skill** is intent-triggered: Claude reaches for it when you ask for a prompt to be
improved in plain English ("make this prompt better", "turn this into a reusable prompt"). Keep
both — the command for muscle memory, the skill for when you forget it exists.

## Manual install (step by step)

**Step 1 — Shared instructions.** Copy `enhance.md` to `~/.config/prompt-enhancer/enhance.md`.
This one file is the single source of truth; editing it updates every entry point at once.

**Step 2 — Claude Code.** Any `.md` file in `~/.claude/commands/` becomes a slash command. Copy
`claude/commands/enhance.md` there — it's a thin wrapper that pulls in the shared file and
appends your input:

```markdown
---
description: Turn a rough prompt into a polished, reusable prompt (asks clarifying questions first)
---
@~/.config/prompt-enhancer/enhance.md

The rough prompt to enhance:
$ARGUMENTS
```

For the skill, copy `claude/skills/enhance/SKILL.md` to `~/.claude/skills/enhance/SKILL.md`.

**Step 3 — Copilot CLI.** Copilot CLI has no custom slash commands yet, so a small shell
function opens an interactive Copilot session seeded with the shared instructions — it can still
ask you questions. `--effort low` keeps this refiner step cheap. Append `copilot/enhance.zsh` to
`~/.zshrc` (or `~/.bashrc` / `~/.bash_profile` for bash):

```bash
enhance() {
  copilot --effort low -i "$(cat ~/.config/prompt-enhancer/enhance.md)

The rough prompt to enhance:
$*"
}
```

Then reload: `source ~/.zshrc`.

## Verify it works

1. **Claude Code:** open a *new* session and run `/enhance write release notes`. It should ask a
   few questions, then return one tight fenced prompt (with a "be concise" constraint and a "To
   save tokens" list) — without doing the task.
2. **Claude Code skill:** in a new session, say `make this prompt better: write release notes`.
   Same output, no slash command.
3. **Copilot CLI:** run `enhance write release notes`. An interactive session opens at low
   effort, already asking clarifying questions; after you answer you get the polished prompt.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/enhance` ignores the instructions and just answers normally | Claude didn't expand the `@`-include. Paste the full contents of `~/.config/prompt-enhancer/enhance.md` directly into `~/.claude/commands/enhance.md`, above the `$ARGUMENTS` line. |
| The skill never triggers | It's intent-based, so phrasing matters — say "enhance this prompt" / "make this prompt better". Check `~/.claude/skills/enhance/SKILL.md` exists and start a new session. |
| `enhance: command not found` | You didn't reload the shell. Run `source ~/.zshrc` or open a new terminal. |
| `copilot: command not found` when running `enhance` | Install / authenticate GitHub Copilot CLI first, and make sure `copilot` is on your `PATH`. |
| Refiner feels too shallow at `--effort low` | It's tuned cheap on purpose. For a tougher prompt, bump the function to `--effort medium`. |

## Customizing

To change how the enhancer behaves (number of questions, output structure, tone, token rules),
edit `enhance.md` here and re-run `./install.sh` — or edit
`~/.config/prompt-enhancer/enhance.md` directly for a machine-local tweak. Every entry point
picks the change up immediately; no other edits needed.

## Uninstall

```bash
./uninstall.sh                 # removes the command, the skill, and the shell function
./uninstall.sh --claude-only   # keep the Copilot function
./uninstall.sh --purge         # also deletes ~/.config/prompt-enhancer
```

`--copilot-only`, `--rc <path>` and `--dry-run` work here too.

It backs up your rc file before editing it, and only strips the block it added (marked with
`# >>> Prompt Enhancer >>>`). An older hand-pasted block is reported for you to delete by hand
rather than edited blindly.

## License

MIT — see [LICENSE](LICENSE).
