---
name: jujutsu
description: "**REQUIRED** - ALways activate FIRST on any git/VCS operations (commit, status, branch, push, etc.), especially when HEAD is detached. If `.jj/` exists -> this is a Jujutsu (jj) repo - git commands will corrupt data. Essential git safety instructions inside. DO NOT IGNORE."
allowed-tools: Bash(jj *)
---

# Jujutsu (jj) Version Control System

This skill helps you work with Jujutsu, a Git-compatible VCS with mutable commits and automatic rebasing.

**Tested with jj v0.40.0** - Commands may differ in other versions.

## Important: Automated/Agent Environment

When running as an agent:

1. **Always use `-m` flags** to provide messages inline rather than relying on editor prompts:

```bash
# Always use -m to avoid editor prompts
jj desc -m "message"      # NOT: jj desc
jj new -m "message"       # NOT: jj new && jj desc -m "..." (two steps when one works)
jj squash -m "message"    # NOT: jj squash (which opens editor)
```

Editor-based commands will fail in non-interactive environments.

2. **Verify operations with `jj st`** after mutations (`squash`, `abandon`, `rebase`, `restore`) to confirm the operation succeeded.

## Core Concepts

### The Working Copy is a Commit

In jj, your working directory is always a commit (referenced as `@`). Changes are automatically snapshotted when you run any jj command. There is no staging area.

There is no need to run `jj commit`.

### Commits Are Mutable

**CRITICAL**: Unlike git, jj commits can be freely modified. This enables a high-quality commit workflow:

1. Before starting work, run `jj st`. If `@` already has changes, run `jj new` first. If `@` is empty, use it as-is.
2. Describe your intended changes with `jj desc -m"Message"`
3. Make your changes.
4. Do NOT run `jj new` when finished — leave that to the next task's step 1.

You may refine the commit using `jj squash` or `jj absorb` as needed

### Change IDs vs Commit IDs

- **Change ID**: A stable identifier (like `tqpwlqmp`) that persists when a commit is rewritten
- **Commit ID**: A content hash (like `3ccf7581`) that changes when commit content changes

Prefer using Change IDs when referencing commits in commands.

## Essential Workflow

### Starting Work: Describe First, Then Code

**Always create your commit message before writing code:**

```bash
# First, describe what you intend to do
jj desc -m "Add user authentication to login endpoint"

# Then make your changes - they automatically become part of this commit
# ... edit files ...

# Check status
jj st
```

### Creating Atomic Commits

Each commit should represent ONE logical change. Use this format for commit messages:

```
Examples:
- "Add validation to user input forms"
- "Fix null pointer in payment processor"
- "Remove deprecated API endpoints"
- "Update dependencies to latest versions"
```

### Viewing History

```bash
# View recent commits
jj log

# View with patches
jj log -p

# View specific commit
jj show <change-id>

# View diff of working copy in readable format
jj diff --git --color never
```

### Moving Between Commits

```bash
# Create a new empty commit on top of current
jj new

# Create new commit with message (single command)
jj new -m "Commit message"

# Edit an existing commit (working copy becomes that commit)
jj edit <change-id>

# Edit the previous commit
jj prev -e

# Edit the next commit
jj next -e
```

## Refining Commits

### Squashing Changes

Move changes from current commit into its parent, or between arbitrary commits:

```bash
# Squash all changes into parent
jj squash

# Squash into a specific commit (not just parent)
jj squash --into <change-id>

# Move changes from one commit into another (neither needs to be @)
jj squash --from <source-id> --into <dest-id>

# Squash only specific paths
jj squash path/to/file.txt
```

**Note**: `jj squash -i` opens an interactive UI and will hang in agent environments. Avoid it.

### Splitting Commits

`jj split` **without arguments** is interactive and will hang in agent environments. But `jj split <paths>` works non-interactively — it splits the listed paths into the first of two commits:

```bash
# Split current commit: listed paths stay in @-, remaining changes go to @
jj split path/to/file.txt other/file.swift

# Split a specific commit by change ID
jj split -r <change-id> path/to/file.txt

# --parallel makes the two resulting commits siblings rather than parent/child
jj split --parallel path/to/file.txt
```

Avoid `jj split -i` (interactive diff editor).

### Absorbing Changes

Automatically distribute changes to the commits that last modified those lines:

```bash
# Absorb working copy changes into appropriate ancestor commits
jj absorb
```

### Abandoning Commits

Remove a commit entirely (descendants are rebased to its parent):

```bash
jj abandon <change-id>
```

### Undoing Operations

Reverse the last jj operation:

```bash
jj undo
```

This reverts the repository to its state before the previous command. Useful for recovering from mistakes like accidental `abandon`, `squash`, or `rebase`.

**For deeper recovery, use the operation log.** `jj undo` only reverses the immediately prior op; after several operations it gets confusing. `jj op log` + `jj op restore` are far more powerful:

```bash
# See every operation jj has performed, with IDs
jj op log

# Jump back to the repo state at a specific operation (like a time machine)
jj op restore <op-id>

# Show what changed in one operation
jj op show <op-id>
```

This is the real safety net — almost nothing in jj is actually lost, just unreachable from the current op.

### Rebasing

```bash
# Rebase the current commit (and its descendants) onto a new parent
jj rebase -d <dest>

# Rebase a specific commit and its descendants
jj rebase -s <source> -d <dest>

# Rebase only one commit (no descendants move)
jj rebase -r <change-id> -d <dest>

# Rebase an entire branch (everything from source back to the common ancestor with dest)
jj rebase -b <source> -d <dest>
```

`-d` can also take multiple destinations to create a merge commit.

### Restoring Files

Discard changes to specific files or restore files from another revision:

```bash
# Discard all uncommitted changes in working copy (restore from parent)
jj restore

# Discard changes to specific files
jj restore path/to/file.txt

# Restore files from a specific revision
jj restore --from <change-id> path/to/file.txt
```

## Working with Bookmarks (Branches)

Bookmarks are jj's equivalent to git branches:

```bash
# Create a bookmark at current commit (-r@ is the default, can be omitted)
jj bookmark create my-feature

# Move bookmark to a different commit
jj bookmark move my-feature --to <change-id>

# List bookmarks
jj bookmark list

# Delete a bookmark
jj bookmark delete my-feature
```

**Important**: Unlike git branches, bookmarks do NOT auto-advance when you create new commits. After making commits, `jj bookmark move my-feature --to @` is often needed before pushing.

## Git Integration

### Working with Existing Git Repos

```bash
# Clone a git repository
jj git clone <url>

# Initialize jj in an existing git repo
jj git init --colocate
```

### Switching Between jj and git (Colocated Repos)

In a colocated repository (`.jj/` and `.git/` both present), both tools can read the repo, but **prefer jj for all state-changing operations**. Mixing `git checkout`/`git commit`/`git reset` with jj's view of the working copy is a known source of confusion and lost work.

To move to a branch or commit, use jj:

```bash
# Move the working copy to a bookmark (equivalent to `git checkout <branch>`)
jj new <bookmark-name>

# Or edit the bookmark's commit directly
jj edit <bookmark-name>

# Pull remote changes and update bookmarks
jj git fetch
```

Safe to use git for: read-only inspection (`git log`, `git diff`, `git show`), or operations jj doesn't cover (e.g. `git bisect`). After any raw git operation, run `jj st` so jj re-imports the state.

### Pushing Changes

When the user asks you to push changes:

```bash
# Push a specific existing bookmark to the remote
jj git push -b <bookmark-name>

# First push of a new bookmark requires --allow-new (recent jj versions)
jj git push -b <bookmark-name> --allow-new

# Shortcut: create a bookmark at @ and push it in one command
jj git push -c @
```

**Before pushing, ensure:**
1. Your bookmark points to the correct commit (bookmarks don't auto-advance like git branches)
2. The commits are refined and atomic
3. The user has explicitly requested the push

**IMPORTANT**: Unlike git branches, bookmarks do not automatically move when you create new commits. Update before pushing:

```bash
# Move an existing bookmark to the current commit
jj bookmark move my-feature --to @

# Then push it
jj git push -b my-feature
```

**Refusing to push**: jj will refuse to push a bookmark whose commit has an empty description, contains conflicts, or is a merge introducing new changes. Run `jj show <bookmark>` first if a push is rejected.

## Handling Conflicts

jj allows committing conflicts — you can resolve them later:

```bash
# View conflicts
jj st

# List the conflicted paths non-interactively
jj resolve --list
```

**jj's conflict markers are NOT git's markers.** Editing them like git markers will produce a garbage resolution. jj uses a diff-style format that can represent 3-way and N-way conflicts:

```
<<<<<<< Conflict 1 of 1
%%%%%%% Changes from base to side #1
-context line
-removed line
+added line by side 1
+++++++ Contents of side #2
context line
added line by side 2
>>>>>>> Conflict 1 of 1 ends
```

To resolve: delete the entire `<<<<<<< ... >>>>>>>` block and replace it with the final merged content you want. The `%%%%%%%` section is a diff (base → side 1), the `+++++++` section is the literal content of side 2. Reconstruct the intended merged content from those hints.

After editing:
```bash
jj st              # verify no more conflicts
jj resolve --list  # should report nothing
```

Avoid `jj resolve` without args (launches an interactive merge tool). If you'd rather not hand-edit markers, configure a non-interactive tool and pass it: `jj resolve --tool <name> <path>`.

## Immutable Commits

Commits reachable from `trunk()` (typically `main`/`master` and anything merged into it) are **immutable** by default — `jj edit`, `abandon`, `squash`, and `rebase -r` on them will fail with an error like "Commit X is immutable."

This is intentional safety, not a bug. The set is configured via `revset-aliases."immutable_heads()"` (usually `trunk()`). To genuinely rewrite public history (rare — usually the wrong answer), you'd override that config. When you see the error, the right reaction is almost always "make a new commit on top" rather than bypass.

## Revsets (Brief)

Most commands take `-r <revset>` rather than a single ID. A few useful ones:

```bash
# My commits not yet in trunk
jj log -r 'mine() & ~::trunk()'

# The stack leading up to @
jj log -r '::@ & ~::trunk()'

# All descendants of a commit
jj log -r 'descendants(<id>)'

# Commits touching a path
jj log -r 'files("Sources/Screens/Camera/")'
```

Revsets compose: `&` (and), `|` (or), `~` (not), `::x` (ancestors incl. x), `x::` (descendants incl. x). Prefer revsets over looping in shell when operating on multiple commits.

## Preserving Commit Quality

**IMPORTANT**: Because commits are mutable, always refine them:

1. **Review your commit**: `jj show @` or `jj diff`
2. **Is it atomic?** One logical change per commit
3. **Is the message clear?** Use imperative verb phrase in sentence case format with no full stop: "Verb object"
4. **Are there unrelated changes?** Use `jj restore` to move changes out, then create separate commits
5. **Should changes be elsewhere?** Use `jj squash` or `jj absorb`

## Quick Reference

| Action | Command |
|--------|---------|
| Describe current commit | `jj desc -m "message"` |
| View status | `jj st` |
| View log | `jj log` |
| View diff | `jj diff` |
| New commit with message | `jj new -m "message"` |
| Split commit by paths | `jj split <paths>` |
| Edit commit | `jj edit <id>` |
| Squash to parent | `jj squash` |
| Squash to arbitrary commit | `jj squash --into <id>` |
| Auto-distribute changes | `jj absorb` |
| Rebase onto new parent | `jj rebase -d <dest>` |
| Abandon commit | `jj abandon <id>` |
| Undo last op | `jj undo` |
| Deeper recovery | `jj op log` + `jj op restore <op-id>` |
| Restore files | `jj restore [paths]` |
| Create bookmark | `jj bookmark create <name>` |
| Move bookmark | `jj bookmark move <name> --to @` |
| Push new bookmark | `jj git push -b <name> --allow-new` (or `jj git push -c @`) |
| Push existing bookmark | `jj git push -b <name>` |

## Best Practices Summary

1. **Describe first**: Set the commit message before coding
2. **One change per commit**: Keep commits atomic and focused
3. **Use change IDs**: They're stable across rewrites
4. **Refine commits**: Leverage mutability for clean history
5. **Embrace the workflow**: No staging area, no stashing - just commits
