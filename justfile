help: 
    @just --list

# Symlink the skill into ~/.claude/skills so edits here take effect immediately.
install: 
    mkdir -p ~/.claude/skills
    rm -rf ~/.claude/skills/jujutsu
    ln -s "{{justfile_directory()}}/jujutsu" ~/.claude/skills/jujutsu
    @echo "→ Linked ~/.claude/skills/jujutsu to {{justfile_directory()}}/jujutsu"
