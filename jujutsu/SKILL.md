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

2. **For multi-line or special-character descriptions, use `--stdin`** instead of `-m` to avoid shell quoting pitfalls:

```bash
printf '%s\n' "Subject line" "" "Body paragraph with \"quotes\" and \$vars." | jj desc --stdin
```

3. **Verify operations with `jj st`** after mutations (`squash`, `abandon`, `rebase`, `restore`) to confirm the operation succeeded.

4. **Avoid any `-i` / `--interactive` flag** (`squash -i`, `split -i`, `commit -i`, `resolve` without args, `arrange`). These open a TUI diff editor and will hang agents.

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

# Cap output and drop the graph for easier parsing
jj log -n 20 --no-graph

# View with patches
jj log -p

# View specific commit
jj show <change-id>

# Summary-only variants (useful for quickly surveying a change)
jj show --summary <change-id>        # path + add/mod/del per file
jj show --stat <change-id>           # histogram of changes
jj diff --name-only                  # just the paths
jj diff --from <a> --to <b>          # compare two arbitrary revs

# View diff of working copy in readable format
jj diff --git --color never
```

### Inspecting Without Moving `@`

These read a revision without changing the working copy:

```bash
jj file list -r <rev>                # list tracked files in a revision
jj file show -r <rev> path/to/file   # print file contents at a revision
jj file annotate path/to/file        # blame equivalent
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

# Insert a new commit into the middle of a stack (stacked-PR workflows)
jj new --insert-after <change-id> -m "..."
jj new --insert-before <change-id> -m "..."

# Create a merge commit with multiple parents
jj new <rev1> <rev2> -m "Merge branches"
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

# Keep the source revision even if squashing empties it
jj squash --keep-emptied
```

**Note**: `jj squash -i` opens an interactive UI and will hang in agent environments. Avoid it.

If both source and destination have non-empty descriptions, `jj squash` prompts for the combined description in an editor. Pass `-m "..."` or `--use-destination-message` to avoid the prompt.

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

# Keep bookmarks that pointed at the abandoned commit (moved to parent)
jj abandon <change-id> --retain-bookmarks

# Preserve descendants' file contents (instead of re-applying their diffs)
# Useful when the abandoned commit's changes would conflict with descendants
jj abandon <change-id> --restore-descendants
```

### Reverting (Applying the Inverse)

Unlike `git revert`, `jj revert` can insert the inverse commit anywhere:

```bash
# Apply the reverse of a commit on top of @
jj revert -r <change-id> --insert-after @

# Revert at a specific location in history
jj revert -r <change-id> --insert-before <other-id>
```

### Duplicating (Cherry-Pick Equivalent)

```bash
# Copy a commit onto a different parent
jj duplicate <change-id> --onto <dest>

# Copy a commit into the middle of another branch
jj duplicate <change-id> --insert-after <dest>
```

### Editing Metadata Without Changing Content

`jj metaedit` updates author, timestamp, or description without rewriting content:

```bash
jj metaedit -m "New message"              # change description only
jj metaedit --update-author                # refresh author to configured user
jj metaedit --update-author-timestamp      # bump author date to now
```

### Applying Formatters

`jj fix` runs configured code formatters over changed files and updates the containing commits (and descendants):

```bash
jj fix                    # fix @ and its changed files
jj fix -s <change-id>     # fix a specific commit and its descendants
```

Requires `fix.tools.*` config. See `jj help -k config`.

### Seeing How a Change Evolved

`jj evolog` shows every prior version of a change (pre-rebase, pre-squash, etc.) — the real recovery tool when you've mangled a commit and want to see what it looked like before:

```bash
jj evolog                 # history of @
jj evolog -r <change-id>  # history of a specific change
jj evolog -p              # with patches for each version
```

### Comparing Two Versions of a Change

`jj interdiff` compares what two revisions *do* (their patches), not their file contents. The canonical use is checking what's changed locally since you last pushed:

```bash
jj interdiff --from push-xyz@origin --to push-xyz
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

# Revert a *single* operation from the middle of history (inverse of that op only,
# leaving later operations in place). Contrast with op restore which rewinds everything.
jj op revert <op-id>
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
# Create a bookmark (fails if the name already exists)
jj bookmark create my-feature                  # -r defaults to @

# Create-or-update: the primitive agents usually want
jj bookmark set my-feature -r @                # create if missing, move if exists
jj bookmark set my-feature -r @ -B             # -B/--allow-backwards: required when moving backwards/sideways

# Move an existing bookmark (fails if the name doesn't exist)
jj bookmark move my-feature --to <change-id>

# Advance: automatically move the nearest bookmark(s) forward to @
jj bookmark advance -t @

# Rename
jj bookmark rename old-name new-name

# List
jj bookmark list

# Start tracking a remote bookmark as a local one
jj bookmark track my-feature@origin
```

**Important**: Unlike git branches, bookmarks do NOT auto-advance when you create new commits. After making commits, `jj bookmark set my-feature -r @` (or `jj bookmark advance -t @`) is often needed before pushing.

### Delete vs Forget (Important Distinction)

These look similar but behave very differently:

```bash
# Delete: propagates the deletion to the remote on next push
jj bookmark delete my-feature

# Forget: drops the local bookmark only, does NOT push a deletion
# Any corresponding remote bookmark becomes untracked
jj bookmark forget my-feature
```

When undoing a mistaken local bookmark, use `forget` unless you actually want the remote branch deleted.

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
# Push an existing bookmark. If the bookmark is new locally, jj will create it
# on the remote and auto-track it — no --allow-new flag needed in jj 0.40.
jj git push -b <bookmark-name>

# Create a NEW bookmark at a specific revision and push it, in one command.
# Preferred when you know the branch name you want on the remote.
jj git push --named feature/x=@
jj git push --named feature/x=<change-id>

# Same idea but jj picks the name (defaults to push-<change-id>)
jj git push -c @

# Preview without actually pushing
jj git push --dry-run -b <bookmark-name>

# Push every tracked bookmark whose @-position has moved
jj git push --tracked
```

**Safety checks** jj runs automatically (these mirror `git push --force-with-lease`):

- The remote is only updated if it matches what jj last fetched. Run `jj git fetch` if a push is rejected for remote-moved-forward.
- Pushes are refused when the bookmark's commit has an empty description, contains conflicts, is private (`git.private-commits`), or is a new merge commit introducing unpushed work.
  - `jj show <bookmark>` will usually tell you which.
  - Override with `--allow-empty-description` or `--allow-private` only when you actually mean it.

**Before pushing, ensure:**
1. Your bookmark points to the correct commit (bookmarks don't auto-advance like git branches)
2. The commits are refined and atomic
3. The user has explicitly requested the push

**IMPORTANT**: Unlike git branches, bookmarks do not automatically move when you create new commits. Update before pushing:

```bash
# Update bookmark to @ (create-or-move)
jj bookmark set my-feature -r @

# Then push it
jj git push -b my-feature
```

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

This is intentional safety, not a bug. The set is configured via `revset-aliases."immutable_heads()"` (usually `trunk()`). To genuinely rewrite public history (rare — usually the wrong answer), pass the global flag `--ignore-immutable` on the specific command:

```bash
jj --ignore-immutable rebase -r <immutable-id> -d <dest>
```

When you see the error, the right reaction is almost always "make a new commit on top" rather than bypass. Only reach for `--ignore-immutable` with explicit user confirmation.

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
| Describe from stdin (multi-line) | `... \| jj desc --stdin` |
| View status | `jj st` |
| View log (trim for agents) | `jj log -n 20 --no-graph` |
| View diff | `jj diff` |
| Diff paths only / stats | `jj diff --name-only` / `jj diff --stat` |
| Inspect file at a revision | `jj file show -r <id> <path>` |
| Blame | `jj file annotate <path>` |
| New commit with message | `jj new -m "message"` |
| Insert into middle of stack | `jj new --insert-after <id> -m "..."` |
| Split commit by paths | `jj split <paths>` |
| Edit commit | `jj edit <id>` |
| Squash to parent | `jj squash` |
| Squash to arbitrary commit | `jj squash --into <id>` |
| Auto-distribute changes | `jj absorb` |
| Rebase onto new parent | `jj rebase -d <dest>` |
| Abandon commit | `jj abandon <id>` |
| Revert (inverse commit) | `jj revert -r <id> --insert-after @` |
| Cherry-pick equivalent | `jj duplicate <id> --onto <dest>` |
| Edit author/timestamp/desc | `jj metaedit --update-author` etc. |
| See prior versions of a change | `jj evolog -p` |
| Compare two versions of a change | `jj interdiff --from <a> --to <b>` |
| Undo last op | `jj undo` |
| Deeper recovery | `jj op log` + `jj op restore <op-id>` |
| Revert a single op mid-history | `jj op revert <op-id>` |
| Restore files | `jj restore [paths]` |
| Create bookmark | `jj bookmark create <name>` |
| Create-or-update bookmark | `jj bookmark set <name> -r @` |
| Advance nearest bookmark to @ | `jj bookmark advance -t @` |
| Rename bookmark | `jj bookmark rename old new` |
| Forget bookmark (local only) | `jj bookmark forget <name>` |
| Delete bookmark (propagates on push) | `jj bookmark delete <name>` |
| Push existing bookmark | `jj git push -b <name>` |
| Push NEW bookmark with chosen name | `jj git push --named feature/x=@` |
| Push @ with auto-generated name | `jj git push -c @` |
| Preview a push | `jj git push --dry-run -b <name>` |
| Bypass immutability (rare) | `jj --ignore-immutable <cmd>` |

## Best Practices Summary

1. **Describe first**: Set the commit message before coding
2. **One change per commit**: Keep commits atomic and focused
3. **Use change IDs**: They're stable across rewrites
4. **Refine commits**: Leverage mutability for clean history
5. **Embrace the workflow**: No staging area, no stashing - just commits
