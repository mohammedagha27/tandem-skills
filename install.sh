#!/usr/bin/env bash
# Symlink the tandem skill family into ~/.claude/skills (install both together:
# /tandem invokes /tandem-review, and tandem-review reads tandem's codex protocol).
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$SKILLS_DIR"
for skill in tandem tandem-review; do
  target="$SKILLS_DIR/$skill"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "SKIP: $target exists and is not a symlink — remove it first." >&2
    continue
  fi
  ln -sfn "$REPO_DIR/skills/$skill" "$target"
  echo "Installed: $target -> $REPO_DIR/skills/$skill"
done
echo "Done. Restart Claude Code (or start a new session) to pick up the skills."
