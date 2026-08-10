---
name: enhance
description: Turn a rough prompt into one polished, reusable prompt — asks clarifying questions first, then returns a single copy-pasteable prompt and stops. Use when the user wants a prompt improved rather than executed. Triggers on "enhance this prompt", "make this prompt better", "refine/rewrite my prompt", "turn this into a reusable prompt", "help me write a prompt for X".
---

# Prompt Enhancer

Read `~/.config/prompt-enhancer/enhance.md` and follow it verbatim. Treat the user's
request (minus the "enhance this" framing) as the rough prompt to enhance.

That file is the single source of truth — the same one the `/enhance` command and the
Copilot CLI `enhance` function use. Do not paraphrase it from memory.

Two rules that hold even if that file is missing or unreadable:

- **Never execute the task the prompt describes.** You produce a better prompt, nothing else.
- Output exactly: one fenced code block with the enhanced prompt (Role/Context → Task →
  Constraints → Output format → Success criteria, including a "be concise" constraint), then
  the single line `Copy this into Claude, Copilot, or any model.`, then a "To save tokens:"
  list of at most 3 bullets. Then stop — no other commentary.
