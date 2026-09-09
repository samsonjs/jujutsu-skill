# jj VCS Agent Skill

An Agent Skill that helps AI coding agents work with the Jujutsu (jj) version control system.

## Overview

This repository provides an Agent Skill for Claude Code and other compatible AI agents to effectively use the Jujutsu VCS. The skill teaches agents the proper workflow and commands for creating atomic, well-documented commits using jj.

## Compatibility

**Tested with:** jj v0.40.0

This skill is designed for jj v0.40.0 and may work with other versions, though compatibility is not guaranteed.

## What is Jujutsu?

Jujutsu (jj) is a Git-compatible version control system that offers several advantages:

- **Working copy as a commit**: The working directory is always a commit, automatically snapshotting changes
- **No staging area**: Changes are moved directly between commits using `squash` and `split`
- **Automatic rebasing**: Descendant commits are automatically rebased when parent commits change
- **Mutable commits**: Commits can be freely edited, split, and squashed
- **Change IDs**: Stable identifiers that persist across commit rewrites
- **Conflict handling**: Conflicts can be committed and resolved later

## Installation

If you use [just](just.systems), you can run:

```
just install
```

That symlinks `jujutsu/` into `~/.claude/skills/`, so edits in this checkout take
effect without reinstalling.

To install it into a single project instead, symlink it there:

```bash
ln -s "$PWD/jujutsu" /path/to/your/project/.claude/skills/jujutsu
```

Copying works too, but the copy drifts as this repo changes.

## Skill Contents

```
jujutsu/
├── SKILL.md          # Core loop: safety, jj mindset, scratchpad+squash, pushing (always loaded)
└── reference/        # One file per task, read on demand to keep activation cheap
    ├── inspect.md    # History, files-at-rev, blame, moving between changes, stacking
    ├── refine.md     # Split, absorb, abandon, revert, duplicate, metaedit, rebase, immutable
    ├── recover.md    # evolog, undo, op log/restore/revert
    ├── bookmarks.md  # Set/delete/forget/track, tugging forward
    ├── git.md        # Clone/init, colocated repos, push safety
    ├── conflicts.md  # jj's conflict markers and resolution
    └── revsets.md    # Revset syntax
```

## Key Workflow Philosophy

The skill emphasizes:

1. **Describe-first commits**: Use `jj new -m "message"` before making changes
2. **Atomic commits**: Each commit should represent one logical change
3. **Commit quality preservation**: Leverage jj's mutability to refine commits
4. **Clean history**: Use `squash`, `split`, and `absorb` to maintain a readable history

## Contributing

Contributions are welcome. Please ensure any changes are compatible with jj v0.40.0.

## License

MIT
