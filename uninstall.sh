#!/usr/bin/env bash
# Prompt Enhancer uninstaller.
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
  -h, --help       Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-only)  DO_COPILOT=0 ;;
    --copilot-only) DO_CLAUDE=0 ;;
    --purge)   PURGE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --rc)      shift; RC="${1:-}"; [ -n "$RC" ] || { echo "--rc needs a path" >&2; exit 1; } ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$RC" ]; then
  case "${SHELL:-}" in
    *bash) RC="$HOME/.bashrc" ;;
    *)     RC="$HOME/.zshrc" ;;
  esac
fi

say() { printf '%s\n' "$1"; }
run() { [ "$DRY_RUN" -eq 1 ] || "$@"; }

[ "$DRY_RUN" -eq 1 ] && say "(dry run — nothing will be removed)"

remove_path() {
  local path="$1" flag="$2"
  if [ -e "$path" ]; then
    say "  - removing $path"
    run rm $flag "$path"
  else
    say "  = $path not present"
  fi
}

if [ "$DO_CLAUDE" -eq 1 ]; then
  say "Claude Code:"
  remove_path "$CLAUDE_CMD" "-f"
  remove_path "$SKILL_DIR" "-rf"
fi

if [ "$DO_COPILOT" -eq 1 ]; then
  say "Copilot CLI ($RC):"
  if [ ! -f "$RC" ]; then
    say "  = $RC not present"
  elif grep -qF "$BEGIN" "$RC" && grep -qF "$END" "$RC"; then
    say "  - stripping the marked enhance() block (backup: $RC.prompt-enhancer.bak)"
    if [ "$DRY_RUN" -eq 0 ]; then
      cp "$RC" "$RC.prompt-enhancer.bak"
      awk -v b="$BEGIN" -v e="$END" '
        $0 == b { skip = 1 }
        skip != 1 { print }
        $0 == e { skip = 0 }
      ' "$RC.prompt-enhancer.bak" >"$RC"
    fi
  elif grep -q "Prompt Enhancer" "$RC"; then
    say "  ! found an unmarked (pre-installer) enhance() block — remove it by hand:"
    grep -n "Prompt Enhancer" "$RC" | sed 's/^/      /'
    say "      Delete the comment lines above plus the enhance() { ... } function that follows."
  else
    say "  = no enhance() function found"
  fi
fi

say "Shared instructions:"
if [ "$PURGE" -eq 1 ]; then
  remove_path "$CONFIG_DIR" "-rf"
else
  if [ -e "$CONFIG_DIR" ]; then
    say "  = kept $CONFIG_DIR (re-run with --purge to delete it)"
  else
    say "  = $CONFIG_DIR not present"
  fi
fi

say ""
say "Done. Open a new terminal (or source $RC) to drop the enhance() function."
