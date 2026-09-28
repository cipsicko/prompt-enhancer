#!/usr/bin/env bash
# Prompt Enhancer uninstaller.
# Only undoes what install.sh did. If you installed the Claude Code side via
# `/plugin install` instead, use `/plugin uninstall` for that — this script
# doesn't know about plugin-marketplace installs.
set -euo pipefail

CONFIG_DIR="$HOME/.config/prompt-enhancer"
CLAUDE_CMD="$HOME/.claude/commands/enhance.md"
SKILL_DIR="$HOME/.claude/skills/enhance"

BEGIN='# >>> Prompt Enhancer >>>'
END='# <<< Prompt Enhancer <<<'

PURGE=0
DRY_RUN=0
DO_CLAUDE=1
DO_COPILOT=1
NO_COLOR_FLAG=0
RC=""

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

  --claude-only    Remove the slash command and skill only
  --copilot-only   Remove the shell function only
  --purge          Also delete ~/.config/prompt-enhancer (your shared instructions,
                   including any customizations)
  --rc <path>      Shell rc file to clean (default: ~/.zshrc, or ~/.bashrc when $SHELL is bash)
  --dry-run        Print what would be removed without touching anything
  --no-color       Plain output, no colour (also honours the NO_COLOR env var)
  -h, --help       Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-only)  DO_COPILOT=0 ;;
    --copilot-only) DO_CLAUDE=0 ;;
    --purge)        PURGE=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    --no-color)     NO_COLOR_FLAG=1 ;;
    --rc)           shift; RC="${1:-}"; [ -n "$RC" ] || { echo "--rc needs a path" >&2; exit 1; } ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$RC" ]; then
  case "${SHELL:-}" in
    *bash) RC="$HOME/.bashrc" ;;
    *)     RC="$HOME/.zshrc" ;;
  esac
fi

# ---------- presentation ----------

if [ "$NO_COLOR_FLAG" -eq 0 ] && [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''
  C_GREEN=''; C_YELLOW=''; C_RED=''
fi

case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8*|*utf-8*|*UTF8*|*utf8*)
    S_OK='✓'; S_DEL='✗'; S_SKIP='•'; S_WARN='⚠'; S_ARROW='→'; S_DASH='—' ;;
  *)
    S_OK='[ok]'; S_DEL='[x]'; S_SKIP='[-]'; S_WARN='[!]'; S_ARROW='->'; S_DASH='-' ;;
esac

say() { printf '%s\n' "$1"; }
section() { printf '%s%s%s\n' "$C_BOLD" "$1" "$C_RESET"; }
tilde() { printf '%s' "${1/#$HOME/~}"; }

# mark <ok|del|skip|warn> <subject> [dim status]
mark() {
  local sym color
  case "$1" in
    ok)   sym="$S_OK";   color="$C_GREEN"  ;;
    del)  sym="$S_DEL";  color="$C_RED"    ;;
    skip) sym="$S_SKIP"; color="$C_DIM"    ;;
    warn) sym="$S_WARN"; color="$C_YELLOW" ;;
  esac
  if [ -n "${3:-}" ]; then
    printf '  %s%s%s %s  %s%s%s\n' "$color" "$sym" "$C_RESET" "$2" "$C_DIM" "$3" "$C_RESET"
  else
    printf '  %s%s%s %s\n' "$color" "$sym" "$C_RESET" "$2"
  fi
}

run() { [ "$DRY_RUN" -eq 1 ] || "$@"; }

# verb <what happened> <what would happen> — keeps dry-run output in the future tense
verb() { if [ "$DRY_RUN" -eq 1 ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# ---------- remove steps ----------

remove_path() {
  local path="$1" flag="$2" label
  label="$(tilde "$path")"
  if [ -e "$path" ]; then
    run rm $flag "$path"
    mark del "$label" "$(verb removed 'would be removed')"
  else
    mark skip "$label" "not present"
  fi
}

printf '%sPrompt Enhancer %s uninstall%s\n' "$C_BOLD" "$S_DASH" "$C_RESET"
[ "$DRY_RUN" -eq 1 ] && printf '%s(dry run %s nothing will be removed)%s\n' "$C_DIM" "$S_DASH" "$C_RESET"
say ""

if [ "$DO_CLAUDE" -eq 1 ]; then
  section "Claude Code"
  remove_path "$CLAUDE_CMD" "-f"
  remove_path "$SKILL_DIR" "-rf"
fi

if [ "$DO_COPILOT" -eq 1 ]; then
  section "Copilot CLI"
  if [ ! -f "$RC" ]; then
    mark skip "$(tilde "$RC")" "not present"
  elif grep -qF "$BEGIN" "$RC" && grep -qF "$END" "$RC"; then
    if [ "$DRY_RUN" -eq 0 ]; then
      cp "$RC" "$RC.prompt-enhancer.bak"
      awk -v b="$BEGIN" -v e="$END" '
        $0 == b { skip = 1 }
        skip != 1 { print }
        $0 == e { skip = 0 }
      ' "$RC.prompt-enhancer.bak" >"$RC"
    fi
    mark del "enhance() in $(tilde "$RC")" \
      "$(verb removed 'would be removed') (backup: $(basename "$RC").prompt-enhancer.bak)"
  elif grep -q "Prompt Enhancer" "$RC"; then
    mark warn "$(tilde "$RC") has an older enhance() block that this script did not add"
    grep -n "Prompt Enhancer" "$RC" | while IFS= read -r line; do
      printf '    %s%s%s\n' "$C_DIM" "$line" "$C_RESET"
    done
    printf '    %sDelete those comment lines and the enhance() { ... } function below them.%s\n' \
      "$C_DIM" "$C_RESET"
  else
    mark skip "enhance() in $(tilde "$RC")" "not found"
  fi
fi

section "Shared instructions"
if [ "$PURGE" -eq 1 ]; then
  remove_path "$CONFIG_DIR" "-rf"
elif [ -e "$CONFIG_DIR" ]; then
  mark skip "$(tilde "$CONFIG_DIR")" "kept (use --purge to delete)"
else
  mark skip "$(tilde "$CONFIG_DIR")" "not present"
fi

say ""
printf '%s%s%s %sDone%s\n' "$C_GREEN" "$S_OK" "$C_RESET" "$C_BOLD" "$C_RESET"
printf '  %s Open a new terminal, or run %ssource %s%s, to drop the enhance() function.\n' \
  "$S_ARROW" "$C_DIM" "$(tilde "$RC")" "$C_RESET"
