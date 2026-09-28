# Prompt Enhancer

A small tool that turns a rough prompt into a good prompt. It works in **Claude Code** and in
**GitHub Copilot CLI**.

<video src="media/video.mp4" controls width="100%"></video>

**What it does.** You give it a rough idea of what you want to ask an AI. It asks you a few
questions, and then it gives you one clear prompt that you can copy and paste. It does not do the
task itself. You decide where the final prompt goes.

**It saves tokens.** The prompts it writes are short and have no filler text. Every prompt it
writes includes a rule that says "be concise". At the end it also gives you up to three tips to
spend fewer tokens (use a cheaper model, use lower reasoning effort, paste less context). In
Copilot CLI it runs with `--effort low`, so this step is cheap too.

## How to use it

| Tool | Command | Example |
|---|---|---|
| Claude Code | `/enhance <rough prompt>` | `/enhance write release notes` |
| Claude Code (skill) | just ask in normal words | `make this prompt better: write release notes` |
| Copilot CLI | `enhance <rough prompt>` | `enhance write release notes` |

## How it improves your prompt

**Step 1: it reads your rough prompt.** First it decides what kind of task it is (thinking,
finding data, writing, code, research, or rewriting). The kind of task decides which rules it uses
later. Then it looks for problems that only you can fix:

- two rules that cannot both be true, or something that is impossible
- an output format that you clearly need but never described
- a goal that nobody can check

If it finds two rules that do not fit together, it always asks you. It never picks one in silence.

**Step 2: it asks questions.** They come under the header **A few questions first**. It only
asks when your answer would change the result. Normal
topics are: the goal, the reader, the important inputs, the hard limits, the format and the length,
and what a good answer looks like. The number of questions depends on your prompt: about 3 to 5 if
it is vague, few or none if it is already clear, and never more than 6. All questions come in one
numbered list, and each one gives you 2 or 3 options to choose from. In Claude Code you get the
interactive question menu. If you cannot answer a question, it uses a sensible default and marks
it `[ASSUMED]`. It never adds a rule that you did not confirm.

**Step 3: it gives you the prompt.** Under the label **▸ Enhanced prompt** you get one code block,
written as instructions to the model, in this order: Role/Context, Task, Constraints, Output
format, Success criteria. The prompt also:

- **Can be reused.** Anything that changes each time becomes a named placeholder. Text that you
  paste in gets a clear label around it, for example `<transcript>…</transcript>` or
  `[paste the diff here]`.
- **Is exact about structured output.** If you need fields (for example JSON), it names every
  field, its type, the order, and what to do when a value is missing.
- **Asks the model to think first only when this helps** — for example math, debugging, or a
  decision with many limits. For simple tasks it leaves this out, because it would only cost extra
  tokens. It adds "say when you are not sure instead of guessing" when facts must be correct.
- **Keeps your intent.** All limits that you confirmed stay in the prompt. It only removes a rule
  when that rule conflicts with another one.

Then it stops. After the code block you get one line, **→ Copy this into Claude, Copilot, or any
model.**, and a short **⚡ To save tokens:** list with up to three tips. Nothing else.

The symbols only appear around the prompt, never inside the code block. What you copy is always
plain text.

These rules come from other tools and from research: the
[OpenAI prompt optimizer cookbook](https://developers.openai.com/cookbook/examples/optimize_prompts)
(checks for conflicts and for missing formats),
[PRoMPTed](https://aclanthology.org/2024.findings-acl.371.pdf) and
[TAPR](https://arxiv.org/html/2607.28657) (task type first, and which changes really help),
the [Anthropic prompt generator](https://claude.com/blog/prompt-generator) (expert role, labelled
inputs), and two similar skills:
[ndpvt-web/prompt-improver](https://github.com/ndpvt-web/prompt-improver) and
[severity1/claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver).
The git history explains what was left out and why.

## What you need first

- **Claude Code** installed, for `/enhance` and for the skill.
- **GitHub Copilot CLI** installed and logged in, with the `copilot` command available in your
  terminal. You need this only for the `enhance` command.
- A **zsh** shell (this is the default on macOS). Bash also works, see `--rc` below.

You can install only one side if you want. The two sides work on their own.

## Install

```bash
git clone https://github.com/cipsicko/prompt-enhancer.git
cd prompt-enhancer
./install.sh
source ~/.zshrc   # or open a new terminal
```

You can run `install.sh` as often as you like, also after `git pull`. If a file on your machine is
different from the file in this repository (because you changed it), the script saves your version
as a `*.bak` file first. It never deletes your changes without a copy.

Do you already have an older version on your machine? Then go to
[Update an installation that already exists](#update-an-installation-that-already-exists).

The scripts use symbols and colour to show what happened: `✓` already correct, `+` new, `↻`
replaced (with the backup name), `✗` removed, `•` nothing to do, `⚠` warning. Colour is only used
in a terminal. When you send the output to a file or a log, or when you use `--no-color`, or when
the `NO_COLOR` variable is set, you get plain text.

Options:

| Flag | What it does |
|---|---|
| `--claude-only` | Installs the shared file, the command and the skill. Does not touch your shell file. |
| `--copilot-only` | Installs the shared file and the `enhance()` shell function only. |
| `--rc <path>` | Writes the shell function into this file instead (default `~/.zshrc`, or `~/.bashrc` if you use bash). |
| `--dry-run` | Only shows what would change. Writes nothing. |
| `--no-color` | Plain text output, no colour. |

## Update an installation that already exists

If you installed the enhancer before, use these commands to get the newest version:

```bash
cd prompt-enhancer
git pull
./install.sh
```

Good to know:

- Run `./install.sh --dry-run` first if you want to see what will change before you change it.
- The script only copies the files that are different. Files that are already up to date stay as
  they are.
- If you edited a file on your machine, the script saves your version next to it with a `.bak`
  name, for example `~/.config/prompt-enhancer/enhance.md.bak`. Your work is not lost, but the new
  version is now active. To get your old version back, copy the `.bak` file over the new file.
- The script does not touch the function in `~/.zshrc`, because the function is already there. You
  do not need `source ~/.zshrc` this time. The function reads the main file every time you run
  `enhance`, so it uses the new instructions at once.
- Claude Code reads the command and the skill when a session starts. Open a **new** session to use
  the new version.
- If you want to go back to the version before the update, run `git log` to find the older commit,
  then `git checkout <commit> -- .` and `./install.sh` again.

## Which file goes where

| File in this repo | Goes to | What it is for |
|---|---|---|
| `plugins/prompt-enhancer/enhance.md` | `~/.config/prompt-enhancer/enhance.md` | **The main file.** All three entry points read it. |
| `plugins/prompt-enhancer/commands/enhance.md` | `~/.claude/commands/enhance.md` | The `/enhance` command |
| `plugins/prompt-enhancer/skills/enhance/SKILL.md` | `~/.claude/skills/enhance/SKILL.md` | The skill, so Claude can start the enhancer without a command |
| `copilot/enhance.zsh` | added to the end of `~/.zshrc` | The `enhance` shell function |

This repo is also a Claude Code plugin marketplace (`.claude-plugin/marketplace.json` +
`plugins/prompt-enhancer/`). As an alternative to `install.sh` for the Claude Code side, run
`/plugin marketplace add <path-or-url-to-this-repo>` then
`/plugin install prompt-enhancer@prompt-enhancer` — the plugin is self-contained and works right
away. Copilot CLI still needs `install.sh` (or the manual steps below), since it isn't part of the
Claude Code plugin system.

### Command or skill?

Both use the same instructions. The **command** always starts when you type `/enhance …`. The
**skill** starts by itself when you ask for a better prompt in normal words, for example "make this
prompt better" or "turn this into a reusable prompt". Keep both: use the command when you remember
it, and the skill helps you when you forget it.

## Install by hand (step by step)

**Step 1 — the main file.** Copy `plugins/prompt-enhancer/enhance.md` to
`~/.config/prompt-enhancer/enhance.md`. This is the only file with the real instructions. When you
change it, all entry points change too.

**Step 2 — Claude Code.** Every `.md` file in `~/.claude/commands/` becomes a command. Copy
`plugins/prompt-enhancer/commands/enhance.md` to that folder. It is a short file that reads the
main file and adds your text — replace `${CLAUDE_PLUGIN_ROOT}` with the absolute path to
`plugins/prompt-enhancer` in this repo, since that variable only resolves for a real plugin
install:

```markdown
---
description: Turn a rough prompt into a polished, reusable prompt (asks clarifying questions first)
---
Read /path/to/prompt-enhancer/plugins/prompt-enhancer/enhance.md and follow it verbatim.

The rough prompt to enhance:
$ARGUMENTS
```

(`/path/to/prompt-enhancer` is where you cloned this repo — `install.sh` fills this in for you.)

For the skill, copy `plugins/prompt-enhancer/skills/enhance/SKILL.md` to
`~/.claude/skills/enhance/SKILL.md`, making the same replacement.

**Step 3 — Copilot CLI.** Copilot CLI cannot have custom commands yet. So we add a small shell
function. It opens an interactive Copilot session that already contains the instructions, so
Copilot can still ask you questions. The `--effort low` flag keeps this step cheap. Add
`copilot/enhance.zsh` to the end of `~/.zshrc` (or `~/.bashrc` / `~/.bash_profile` if you use
bash):

```bash
enhance() {
  copilot --effort low -i "$(cat ~/.config/prompt-enhancer/enhance.md)

The rough prompt to enhance:
$*"
}
```

Then run `source ~/.zshrc` to load it.

## Check that it works

1. **Claude Code:** open a *new* session and run `/enhance write release notes`. It should ask you
   a few questions with options, and then show **▸ Enhanced prompt** with one short prompt in a
   code block. The prompt should have placeholders and a "be concise" rule, followed by the copy
   line and the **⚡ To save tokens:** list. It should not write the release notes.
2. **Claude Code skill:** in a new session, write `make this prompt better: write release notes`.
   You should get the same result without a command.
3. **Copilot CLI:** run `enhance write release notes`. An interactive session opens at low effort
   and asks you questions. After your answers you get the finished prompt.

## Problems and solutions

| Problem | Solution |
|---|---|
| `/enhance` ignores the instructions and just answers your question | Claude did not read the main file. Check that `~/.claude/commands/enhance.md` points at a real path (not a leftover `${CLAUDE_PLUGIN_ROOT}`) and that the file it points to exists. |
| The skill never starts | The skill reacts to your words, so try: "enhance this prompt", "improve my prompt", "rewrite my prompt", "write me a prompt for X", "turn this into a reusable prompt". Also check that `~/.claude/skills/enhance/SKILL.md` exists, and start a new session. |
| `enhance: command not found` | You did not reload the shell. Run `source ~/.zshrc` or open a new terminal. |
| `copilot: command not found` when you run `enhance` | Install GitHub Copilot CLI, log in, and make sure the `copilot` command works in your terminal. |
| The result feels too simple with `--effort low` | This is on purpose, to keep it cheap. For a difficult prompt, change the function to `--effort medium`. |

## How to change it

You can change how the enhancer works: how many questions it asks, which problems it looks for,
the structure of the result, the tone, when it asks the model to think first, and the token rules.
Edit `plugins/prompt-enhancer/enhance.md` in this repository and run `./install.sh` again. You can
also edit `~/.config/prompt-enhancer/enhance.md` directly, if you only want to change it on this
machine. All entry points use the new version at once. You do not need to change anything else.

## Uninstall

```bash
./uninstall.sh                 # removes the command, the skill and the shell function
./uninstall.sh --claude-only   # keeps the Copilot function
./uninstall.sh --purge         # also deletes ~/.config/prompt-enhancer
```

`--copilot-only`, `--rc <path>`, `--dry-run` and `--no-color` also work here.

The script saves a copy of your shell file before it changes it. It only removes the block that it
added itself, marked with `# >>> Prompt Enhancer >>>`. If you added the function by hand in the
past, the script does not touch it. It shows you the lines, and you delete them yourself.

## License

MIT, see [LICENSE](LICENSE).
