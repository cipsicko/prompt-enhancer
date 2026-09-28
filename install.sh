#!/usr/bin/env bash
# Prompt Enhancer installer — idempotent, safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_DIR="$HOME/.config/prompt-enhancer"
CLAUDE_CMD="$HOME/.claude/commands/enhance.md"
CLAUDE_SKILL="$HOME/.claude/skills/enhance/SKILL.md"

DO_CLAUDE=1
DO_COPILOT=1
DRY_RUN=0
NO_COLOR_FLAG=0
RC=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --claude-only    Install the shared instructions, slash command and skill only
  --copilot-only   Install the shared instructions and the shell function only
  --rc <path>      Shell rc file to append the function to (default: ~/.zshrc, or
                   ~/.bashrc when $SHELL is bash)
  --dry-run        Print what would change without touching anything
  --no-color       Plain output, no colour (also honours the NO_COLOR env var)
  -h, --help       Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-only)  DO_COPILOT=0 ;;
    --copilot-only) DO_CLAUDE=0 ;;
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

# Colour only for a real terminal: not piped, not NO_COLOR, not TERM=dumb, not --no-color.
if [ "$NO_COLOR_FLAG" -eq 0 ] && [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'; C_CYAN=$'\033[36m'; C_YELLOW=$'\033[33m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''
  C_GREEN=''; C_CYAN=''; C_YELLOW=''
fi

# Unicode marks need a UTF-8 locale; fall back to ASCII so nothing renders as mojibake.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8*|*utf-8*|*UTF8*|*utf8*)
    S_OK='✓'; S_NEW='+'; S_UPD='↻'; S_SKIP='•'; S_WARN='⚠'; S_ARROW='→'; S_DASH='—' ;;
  *)
    S_OK='[ok]'; S_NEW='[+]'; S_UPD='[~]'; S_SKIP='[-]'; S_WARN='[!]'; S_ARROW='->'; S_DASH='-' ;;
esac

say() { printf '%s\n' "$1"; }
section() { printf '%s%s%s\n' "$C_BOLD" "$1" "$C_RESET"; }
tilde() { printf '%s' "${1/#$HOME/~}"; }

# mark <ok|new|upd|skip|warn> <subject> [dim status]
mark() {
  local sym color
  case "$1" in
    ok)   sym="$S_OK";   color="$C_GREEN"  ;;
    new)  sym="$S_NEW";  color="$C_GREEN"  ;;
    upd)  sym="$S_UPD";  color="$C_CYAN"   ;;
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

# ---------- install steps ----------

PLUGIN_DIR="$REPO/plugins/prompt-enhancer"

# Copy src -> dest, backing up an existing dest that differs. If subst is set,
# replace the literal string ${CLAUDE_PLUGIN_ROOT} with it first — the plugin's
# own files reference that variable so they're self-contained when installed via
# the Claude Code plugin marketplace, but a manual copy needs a real path.
install_file() {
  local src="$1" dest="$2" subst="${3:-}" label
  label="$(tilde "$dest")"
  if [ -n "$subst" ]; then
    if [ -f "$dest" ] && [ "$(sed "s|\${CLAUDE_PLUGIN_ROOT}|$subst|g" "$src")" = "$(cat "$dest")" ]; then
      mark ok "$label" "up to date"
      return
    fi
  elif [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    mark ok "$label" "up to date"
    return
  fi
  run mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    local bak n=1
    bak="$dest.bak"
    while [ -e "$bak" ]; do n=$((n + 1)); bak="$dest.bak-$n"; done
    run cp "$dest" "$bak"
    if [ "$DRY_RUN" -eq 0 ]; then
      if [ -n "$subst" ]; then sed "s|\${CLAUDE_PLUGIN_ROOT}|$subst|g" "$src" >"$dest"; else cp "$src" "$dest"; fi
    fi
    mark upd "$label" "$(verb updated 'would be updated') (backup: $(basename "$bak"))"
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      if [ -n "$subst" ]; then sed "s|\${CLAUDE_PLUGIN_ROOT}|$subst|g" "$src" >"$dest"; else cp "$src" "$dest"; fi
    fi
    mark new "$label" "$(verb installed 'would be installed')"
  fi
}

printf '%sPrompt Enhancer%s\n' "$C_BOLD" "$C_RESET"
[ "$DRY_RUN" -eq 1 ] && printf '%s(dry run %s nothing will be written)%s\n' "$C_DIM" "$S_DASH" "$C_RESET"
say ""

section "Shared instructions"
install_file "$PLUGIN_DIR/enhance.md" "$CONFIG_DIR/enhance.md"

if [ "$DO_CLAUDE" -eq 1 ]; then
  section "Claude Code"
  install_file "$PLUGIN_DIR/commands/enhance.md" "$CLAUDE_CMD" "$PLUGIN_DIR"
  install_file "$PLUGIN_DIR/skills/enhance/SKILL.md" "$CLAUDE_SKILL" "$PLUGIN_DIR"
fi

if [ "$DO_COPILOT" -eq 1 ]; then
  section "Copilot CLI"
  if [ -f "$RC" ] && grep -q "Prompt Enhancer" "$RC"; then
    mark skip "enhance() already in $(tilde "$RC")" "left untouched"
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      { printf '\n'; cat "$REPO/copilot/enhance.zsh"; } >>"$RC"
    fi
    mark new "enhance() $(verb 'added to' 'would be added to') $(tilde "$RC")" \
      "$(verb "run: source $(tilde "$RC")" '')"
  fi
  command -v copilot >/dev/null 2>&1 || \
    mark warn "'copilot' is not on your PATH $S_DASH install and log in to GitHub Copilot CLI to use enhance()"
fi

say ""
printf '%s%s%s %sDone%s\n' "$C_GREEN" "$S_OK" "$C_RESET" "$C_BOLD" "$C_RESET"
printf '  %s Claude Code  %s/enhance write release notes%s  %s(new session, or just ask Claude for a better prompt)%s\n' \
  "$S_ARROW" "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET"
printf '  %s Copilot CLI  %senhance write release notes%s\n' \
  "$S_ARROW" "$C_CYAN" "$C_RESET"
