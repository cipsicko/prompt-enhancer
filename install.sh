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
RC=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --claude-only    Install the shared instructions, slash command and skill only
  --copilot-only   Install the shared instructions and the shell function only
  --rc <path>      Shell rc file to append the function to (default: ~/.zshrc, or
                   ~/.bashrc when $SHELL is bash)
  --dry-run        Print what would change without touching anything
  -h, --help       Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-only)  DO_COPILOT=0 ;;
    --copilot-only) DO_CLAUDE=0 ;;
    --dry-run)      DRY_RUN=1 ;;
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

say() { printf '%s\n' "$1"; }
run() { [ "$DRY_RUN" -eq 1 ] || "$@"; }

# Copy src -> dest, backing up an existing dest that differs.
install_file() {
  local src="$1" dest="$2" label="$3"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    say "  = $label already up to date"
    return
  fi
  run mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    local bak n=1
    bak="$dest.bak"
    while [ -e "$bak" ]; do n=$((n + 1)); bak="$dest.bak-$n"; done
    say "  ~ $label differs — backing up to $(basename "$bak")"
    run cp "$dest" "$bak"
    run cp "$src" "$dest"
    say "  + $label updated"
  else
    run cp "$src" "$dest"
    say "  + $label installed"
  fi
}

say "Prompt Enhancer"
[ "$DRY_RUN" -eq 1 ] && say "(dry run — nothing will be written)"

say "Shared instructions:"
install_file "$REPO/enhance.md" "$CONFIG_DIR/enhance.md" "$CONFIG_DIR/enhance.md"

if [ "$DO_CLAUDE" -eq 1 ]; then
  say "Claude Code:"
  install_file "$REPO/claude/commands/enhance.md" "$CLAUDE_CMD" "$CLAUDE_CMD"
  install_file "$REPO/claude/skills/enhance/SKILL.md" "$CLAUDE_SKILL" "$CLAUDE_SKILL"
fi

if [ "$DO_COPILOT" -eq 1 ]; then
  say "Copilot CLI ($RC):"
  if [ -f "$RC" ] && grep -q "Prompt Enhancer" "$RC"; then
    say "  = enhance() function already present — left untouched"
  else
    say "  + appending enhance() function"
    if [ "$DRY_RUN" -eq 0 ]; then
      { printf '\n'; cat "$REPO/copilot/enhance.zsh"; } >>"$RC"
    fi
  fi
  command -v copilot >/dev/null 2>&1 || \
    say "  ! 'copilot' is not on your PATH — install/authenticate GitHub Copilot CLI to use enhance()"
fi

say ""
say "Done."
say "  Claude Code: /enhance write release notes   (new session), or just ask Claude to enhance a prompt"
say "  Copilot CLI: source $RC   then   enhance write release notes"
