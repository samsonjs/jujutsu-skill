#!/bin/sh
# Symlink the skill into ~/.claude/skills so edits in this checkout take effect immediately.
# Pass a different skills directory to install somewhere else, e.g. a single project:
#   ./install.sh /path/to/project/.claude/skills
set -eu

skill=jujutsu
src="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/$skill"
dest="${1:-$HOME/.claude/skills}"

mkdir -p "$dest"
rm -rf "$dest/$skill"
ln -s "$src" "$dest/$skill"
echo "→ Linked $dest/$skill to $src"
