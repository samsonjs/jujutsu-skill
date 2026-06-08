---
name: jujutsu
description: "**REQUIRED** - ALways activate FIRST on any git/VCS operations (commit, status, branch, push, etc.), especially when HEAD is detached. If `.jj/` exists -> this is a Jujutsu (jj) repo - git commands will corrupt data. Essential git safety instructions inside. DO NOT IGNORE."
allowed-tools: Bash(jj *)
---

# Jujutsu (jj) Version Control System

This skill helps you work with Jujutsu, a Git-compatible VCS with mutable commits and automatic rebasing.

**Tested with jj v0.40.0** - Commands may differ in other versions.

## Think in jj, Not in Git

jj is Git-compatible, but the user works in jj and thinks in jj — so should you. The failure mode is narrating and reasoning in git terms ("amend the commit", "the branch", "is HEAD pushed?"). The rest of this skill explains jj by analogy to git to get you oriented; once oriented, drop the analogy and reason in jj's own model. Don't translate jj back into git in your thinking or your replies.

- **The working copy is a change, always.** There is no staging, no "committing", no "amending". Editing files just updates the change at `@`. This is not an event — never narrate it ("jj auto-amended the commit", "the edit got folded into the commit"). The user is not thinking about commits 99% of the time; neither should you.
- **Refer to work by what it is, not by SHAs.** Say "the VNC change" or "the change at `@`", not "commit 3c52cf9b" or "HEAD". Reach for commit IDs only when pointing at a specific historical snapshot.
- **Bookmarks are incidental labels for pushing, not branches you live on.** You don't "switch branches" or "work on `main`". You work on a change; a bookmark may happen to point at it when it's time to push.
- **An empty `@` on top is normal.** After `jj squash` or `jj git push`, jj leaves a fresh empty `@`. That is the expected resting state, not a problem to fix or a surprise to explain.
- **Reason about state in jj terms.** Ask what a change *is* and whether it's described/pushed — not whether `HEAD` matches a ref or a branch is "ahead/behind".

**Vocabulary:** "change" not "commit"; "describe a change" not "make a commit"; "the change at `@`" not "HEAD"; "point a bookmark at" not "create a branch". Only use git vocabulary when the user does, or when explaining the git-interop layer itself.

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

### The Working Copy is a Change

In jj, your working copy is always a change (referenced as `@`). Edits are automatically snapshotted into it whenever you run any jj command. There is no staging area.

There is no need to run `jj commit`.

### Changes Are Mutable

Unlike git, jj changes can be freely modified — described, redescribed, split, squashed, rebased, abandoned. You don't have to get a change "right" up front; you can keep editing it as long as you like.

This is what makes the [scratchpad + squash](#the-inner-loop-scratchpad--squash) loop possible: instead of treating each commit as a one-shot event on a branch, you keep your real change as a parent and use an anonymous child as a workbench you fold in (or throw away) as you go.

### Change IDs vs Commit IDs

- **Change ID** (like `tqpwlqmp`): a stable identifier for the *idea* of the change. Survives rewrites — squash, rebase, redescribe all preserve it.
- **Commit ID** (like `3ccf7581`): a content hash for one specific snapshot. Changes whenever the change's content does.

Almost always reference things by **change ID** in commands. Commit IDs are useful mainly when you need to point at a specific historical snapshot (see `jj evolog`).

## The Inner Loop: Scratchpad + Squash

The idiomatic jj loop is layered. Two changes are in play:

- **Parent**: the change you'll eventually push. Has a description.
- **`@` (scratchpad)**: an anonymous child on top. No description. Treated like git's index — a place to iterate, run tests, undo, redo. Folded into the parent or abandoned.

```bash
jj new -m "Add user authentication"   # parent — what you're shipping
jj new                                # scratchpad — no message
# edit, test, repeat
jj diff                               # review the scratchpad
jj squash                             # fold into parent; fresh empty @ on top
# OR
jj abandon                            # throw the scratchpad away; back on parent
```

After `jj squash` you're back on a fresh empty `@`, ready for the next iteration. Run as many scratchpad → squash cycles as you want; each one means "I made progress, keep it." If a scratchpad is heading nowhere, `jj abandon` returns you to the parent untouched.

The parent's commit ID changes on every squash, but its **change ID is stable** — that's why you reference it by change ID.

### Parallel Experiments

Want to try a different approach without losing the current scratchpad? Start a sibling on the same parent:

```bash
jj new <parent-id>                    # new scratchpad, sibling to the current @
```

Now there are two children of the parent. Iterate in either, abandon the loser, squash the winner. Switch between them with `jj edit <change-id>`. Note: `--insert-after <parent-id>` is different — it inserts the new commit *between* parent-id and its existing children (rebasing those children on top).

### When the Scratchpad Is Overkill

Tiny one-shot work (typo fix, single-line tweak): describe `@` directly and edit. Skip the scratchpad layer.

```bash
jj new -m "Fix typo in error message"
# edit
```

The scratchpad's value is being able to throw away dead-ends without polluting the parent's history. If there's no risk of dead-ends, the layer is overhead.

### Stacking

For multiple related changes, repeat the loop on top of the previous parent:

```bash
jj new -m "Add user authentication"   # change A
jj new                                # scratchpad on A
# work, squash...
jj new -m "Add session management"    # change B, on top of A
jj new                                # scratchpad on B
# work, squash...
```

You end up with a stack: `A ← B ← @`. Push as separate PRs (e.g. via `gh-stack`) or roll them up.

## Inspecting and Navigating

### Viewing History

```bash
# View recent commits
jj log

# Cap output and drop the graph for easier parsing
jj log -n 20 --no-graph

# View with patches
jj log -p

# Show a specific change
jj show <change-id>

# Summary-only variants (useful for quickly surveying a change)
jj show --name-only <change-id>      # just the paths changed
jj show --stat <change-id>           # histogram of changes per file
jj diff --name-only                  # just the paths (working copy)
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

### Moving Between Changes

In the scratchpad workflow, the primary "move" is `jj new` — start a fresh empty change on top, or as a sibling. `jj edit` is for jumping back to a specific change, which you'll usually want to *modify* via a new scratchpad on top + squash, not by editing in place.

```bash
# Start an anonymous scratchpad on top of @
jj new

# Same, with a description (this is a "real" change, not a scratchpad)
jj new -m "Description"

# Insert a new change into the middle of a stack
jj new --insert-after <change-id> -m "..."
jj new --insert-before <change-id> -m "..."

# Sibling scratchpad — for parallel experiments off the same parent
jj new <parent-id>

# Create a merge commit with multiple parents
jj new <rev1> <rev2> -m "Merge branches"

# Jump @ to an existing change (use sparingly — prefer new+squash for edits)
jj edit <change-id>
jj prev -e        # @ becomes the previous change
jj next -e        # @ becomes the next change
```

## Refining Changes

### Squashing

Move part of the current change into its parent, or between arbitrary changes:

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

If both source and destination have non-empty descriptions, `jj squash` prompts for the combined description in an editor. To avoid the prompt:

- **Prefer `-m "..."`** — always safe, you supply the final message explicitly.
- **`--use-destination-message`** keeps the destination's description and discards the source's. Only use this when you are certain the destination has the real description. In the normal scratchpad workflow (`jj squash` with no args) the destination is the parent `@-`, which is correct. But if the destination is an anonymous change with an empty description — e.g. because source/destination are accidentally reversed — `--use-destination-message` will silently discard the real message. When in doubt, use `-m`.

### Splitting

`jj split` **without arguments** is interactive and will hang in agent environments. But `jj split <paths>` works non-interactively — it splits the listed paths into the first of two changes:

```bash
# Split current commit: listed paths stay in @-, remaining changes go to @
jj split path/to/file.txt other/file.swift

# Split a specific commit by change ID
jj split -r <change-id> path/to/file.txt

# --parallel makes the two resulting commits siblings rather than parent/child
jj split --parallel path/to/file.txt
```

Avoid `jj split -i` (interactive diff editor).

### Absorbing

Automatically fold each hunk into the ancestor change that last modified those lines:

```bash
# Absorb working copy changes into appropriate ancestor commits
jj absorb
```

### Abandoning

Remove a change entirely (descendants are rebased to its parent):

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

`jj fix` runs configured code formatters over changed files and updates the changes containing them (and descendants):

```bash
jj fix                    # fix @ and its changed files
jj fix -s <change-id>     # fix a specific commit and its descendants
```

Requires `fix.tools.*` configured in `~/.config/jj/config.toml` first — without it, `jj fix` is a no-op. See `jj help -k config` for the format.

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

_**NOTE**: Don't try to run `jj op undo` that command does not exist._

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

You usually don't need bookmarks. `jj git push -c @` and `jj git push --named name=@` create-and-push in one step (see [Pushing Changes](#pushing-changes)). Reach for the commands below only when a named local ref earns its keep — updating an already-pushed branch, sharing a ref name across multiple commands, or stacked-PR work.

```bash
jj bookmark set my-feature -r @            # create or move; -B to allow moving backwards/sideways
jj bookmark list
jj bookmark rename old new
jj bookmark track my-feature@origin        # start tracking a remote bookmark
```

### Delete vs Forget

```bash
jj bookmark delete my-feature              # marks for deletion; propagates to remote on next push
jj bookmark forget my-feature              # drops local only; remote bookmark becomes untracked
```

Use `forget` when undoing a local mistake. Use `delete` only when you actually want the remote branch gone.

**Pushing a deleted bookmark**: `jj bookmark delete` only marks it locally. To propagate the deletion to the remote, push by name — jj sends a delete to the remote:

```bash
jj bookmark delete my-feature
jj git push -b my-feature          # sends the deletion to the remote
```

`jj git push --deleted` (no argument) pushes ALL pending bookmark deletions at once. There is **no `--deleted <name>` form** — `--deleted` is a boolean flag, not a parameter that takes a name.

### Tugging Bookmarks Forward

Bookmarks don't auto-advance when you squash or rebase. After iterating on a change, the bookmark may be pointing at an older version and needs to be dragged up.

**When you know the bookmark name** — just set it directly:

```bash
jj bookmark set my-feature -r @-   # or whatever revision it should point at
jj bookmark set main -r @-         # -B only needed when moving backwards/sideways
```

**When you don't know which bookmark is lagging** — use the revset to find the nearest one:

```bash
jj bookmark move --from "heads(::@ & bookmarks())" --to @
```

The revset `heads(::@ & bookmarks())` finds the closest bookmark ancestor of `@`. Worth defining as a config alias if you do this often, but reach for named `bookmark set` first when you already know what you're moving.

## Git Integration

### Working with Existing Git Repos

```bash
# Clone a git repository
jj git clone <url>

# Initialize jj in an existing git repo
jj git init --colocate
```

### Switching Between jj and git (Colocated Repos)

In a colocated repository (`.jj/` and `.git/` both present), both tools can read the repo, but **prefer jj for all state-changing operations**. Mixing `git checkout` / `git commit` / `git reset` with jj's view of the working copy is a known source of confusion and lost work.

```bash
jj new <bookmark-or-rev>     # start a fresh change on top of a ref (≈ git checkout + commit)
jj edit <bookmark-or-rev>    # jump @ onto that change directly
jj git fetch                 # pull remote changes and update tracked bookmarks
```

Safe to use git for: read-only inspection (`git log`, `git diff`, `git show`), or operations jj doesn't cover (e.g. `git bisect`). After any raw git operation, run `jj st` so jj re-imports the state.

### Pushing Changes

**Default to one-shot push commands. Don't create bookmarks manually unless you have a reason to.**

The two commands that should cover ~90% of pushes:

```bash
# Push @ with an auto-generated name (push-<change-id>). Use this when you don't
# care about the remote branch name — most feature/PR work fits here.
jj git push -c @

# Push @ under a name you choose. Use when the branch name matters
# (convention, ticket prefix, user asked for a specific name).
jj git push --named feature/auth-fix=@
jj git push --named bug/1234=<change-id>
```

Both create the bookmark, push it, and set up tracking in a single command. No prior `jj bookmark create` or `jj bookmark set` needed. No `--allow-new` flag needed in jj 0.40.

**Only fall back to `jj git push -b <name>` when the bookmark already exists** — typically because you pushed earlier and now want to update the same branch with new commits. Even then, remember bookmarks don't auto-advance:

```bash
# Updating a previously-pushed branch with new work on @
jj bookmark set my-feature -r @ -B   # -B because you're moving it forward
jj git push -b my-feature
```

Other useful flags:

```bash
# Preview without pushing
jj git push --dry-run -c @

# Push every tracked bookmark whose @-position has moved
jj git push --tracked
```

**Safety checks** jj runs automatically (these mirror `git push --force-with-lease`):

- The remote is only updated if it matches what jj last fetched. Run `jj git fetch` if a push is rejected for remote-moved-forward.
- Pushes are refused when the commit has an empty description, contains conflicts, is private (`git.private-commits`), or is a new merge commit introducing unpushed work.
  - `jj show <rev>` will usually tell you which.
  - Override with `--allow-empty-description` or `--allow-private` only when you actually mean it.

**Before pushing, ensure:**
1. The commit at `@` (or whatever you're pushing) is the right one
2. The commits are refined and atomic
3. The user has explicitly requested the push

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

## Refining a Change Before Pushing

Mutability is the point — refine freely. Before a change leaves your machine:

1. **Review** with `jj show <change-id>` or `jj diff -r <change-id>`
2. **Atomic?** If it spans two ideas, `jj split <paths>` or move pieces with `jj squash --from / --into`
3. **Message clear?** Use an imperative verb phrase in sentence case, no full stop: "Verb object". Update with `jj desc -m "..."` (or `jj metaedit -m "..."` if you want to change just the description without altering the snapshot)
4. **Unrelated changes leaked in?** `jj restore <paths>` to drop them
5. **Belongs in an ancestor?** `jj squash --into <id>` or `jj absorb`

## Quick Reference

### Inner loop

| Action | Command |
|--------|---------|
| Status / diff of scratchpad | `jj st` / `jj diff` |
| Start parent change (with description) | `jj new -m "message"` |
| Start anonymous scratchpad on top | `jj new` |
| Sibling scratchpad off same parent | `jj new <parent-id>` |
| Fold scratchpad into parent | `jj squash` |
| Throw scratchpad away | `jj abandon` |
| Drop uncommitted edits in scratchpad | `jj restore [paths]` |
| Update parent's description | `jj desc -m "..."` (on @-) or `jj metaedit -m "..." -r <id>` |

### Pushing

| Action | Command |
|--------|---------|
| Push @ with auto-generated name (default) | `jj git push -c @` |
| Push @ with a chosen name | `jj git push --named feature/x=@` |
| Update an existing pushed bookmark | `jj bookmark set <name> -r @ -B && jj git push -b <name>` |
| Preview a push | `jj git push --dry-run -c @` |

### Inspect / navigate

| Action | Command |
|--------|---------|
| Log (trim for agents) | `jj log -n 20 --no-graph` |
| Show a change | `jj show <change-id>` |
| Diff paths / stats | `jj diff --name-only` / `jj diff --stat` |
| File contents at a revision | `jj file show -r <id> <path>` |
| Blame | `jj file annotate <path>` |
| Jump @ to a change | `jj edit <change-id>` |

### Refine / rearrange

| Action | Command |
|--------|---------|
| Squash into a non-parent | `jj squash --into <id>` |
| Move bits between changes | `jj squash --from <src> --into <dst>` |
| Split by paths | `jj split <paths>` |
| Auto-distribute to ancestors | `jj absorb` |
| Rebase onto new parent | `jj rebase -d <dest>` |
| Abandon a change | `jj abandon <id>` |
| Inverse-commit (revert) | `jj revert -r <id> --insert-after @` |
| Copy a change elsewhere | `jj duplicate <id> --onto <dest>` |
| Edit author/timestamp/desc | `jj metaedit ...` |

### Recover

| Action | Command |
|--------|---------|
| See prior versions of a change | `jj evolog -p` |
| Compare two versions of a change | `jj interdiff --from <a> --to <b>` |
| Undo last op | `jj undo` |
| Deeper recovery | `jj op log` + `jj op restore <op-id>` |
| Revert a single op mid-history | `jj op revert <op-id>` |
| Bypass immutability (rare) | `jj --ignore-immutable <cmd>` |

### Bookmarks (rare)

| Action | Command |
|--------|---------|
| Create-or-move bookmark | `jj bookmark set <name> -r @` (`-B` to move backwards/sideways) |
| Move a known bookmark to a rev | `jj bookmark set <name> -r <rev>` |
| Tug nearest bookmark up to @ | `jj bookmark move --from "heads(::@ & bookmarks())" --to @` |
| Forget local bookmark | `jj bookmark forget <name>` |
| Delete locally + push deletion | `jj bookmark delete <name> && jj git push -b <name>` |
| Push all pending deletions | `jj git push --deleted` (no argument — pushes ALL deleted bookmarks) |

## Best Practices Summary

1. **Layer your work**: parent change with a description, anonymous scratchpad on top. Squash when good, abandon when not.
2. **Reference by change ID**: stable across rewrites. Commit IDs are for specific snapshots.
3. **Refine before pushing, not before coding**: mutability means you don't have to plan the perfect change up front. Iterate, then clean up.
4. **Push with `-c @` or `--named`**: don't bother creating bookmarks manually for normal PR work.
5. **Trust the op log**: `jj op log` + `jj op restore` is your safety net. Almost nothing is truly lost.
