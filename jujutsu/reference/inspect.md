# Inspecting & Navigating

History, reading revisions without moving `@`, moving between changes, parallel experiments, stacking. Reminders: pass `--git` to any diff, prefer `jj log -n N --no-graph` for parseable output.

## Viewing history

```bash
jj log                                # recent commits
jj log -n 20 --no-graph               # cap output, drop graph for easier parsing
jj log -p --git                       # with patches
jj show <change-id>                   # show a specific change
jj show --name-only <change-id>       # just the paths changed
jj show --stat <change-id>            # histogram of changes per file
jj diff --name-only                   # just the paths (working copy)
jj diff --from <a> --to <b> --git     # compare two arbitrary revs
jj diff --git                         # working copy diff, readable unified format
```

## Inspecting without moving `@`

These read a revision without changing the working copy:

```bash
jj file list -r <rev>                 # list tracked files in a revision
jj file show -r <rev> path/to/file    # print file contents at a revision
jj file annotate path/to/file         # blame equivalent
```

## Moving between changes

In the scratchpad workflow the primary "move" is `jj new` — a fresh empty change on top, or as a sibling. `jj edit` jumps back to a specific change, but you'll usually want to *modify* it via a new scratchpad on top + squash, not edit in place.

```bash
jj new                                # anonymous scratchpad on top of @
jj new -m "Description"               # a "real" described change, not a scratchpad
jj new --insert-after <change-id> -m "..."   # insert into the middle of a stack
jj new --insert-before <change-id> -m "..."
jj new <parent-id>                    # sibling scratchpad — parallel experiments off same parent
jj new <rev1> <rev2> -m "Merge"       # merge commit with multiple parents
jj edit <change-id>                   # jump @ to an existing change (prefer new+squash for edits)
jj prev -e                            # @ becomes the previous change
jj next -e                            # @ becomes the next change
```

## Parallel experiments

Want to try a different approach without losing the current scratchpad? Start a sibling on the same parent:

```bash
jj new <parent-id>                    # new scratchpad, sibling to current @
```

Now there are two children of the parent. Iterate in either, abandon the loser, squash the winner. Switch with `jj edit <change-id>`. Note: `--insert-after <parent-id>` is different — it inserts the new commit *between* parent-id and its existing children (rebasing those children on top).

## Stacking

For multiple related changes, repeat the loop on top of the previous parent:

```bash
jj new -m "Add user authentication"   # change A
jj new                                # scratchpad on A; work, squash...
jj new -m "Add session management"    # change B, on top of A
jj new                                # scratchpad on B; work, squash...
```

You end up with a stack `A ← B ← @`. Push as separate PRs (e.g. via `gh-stack`) or roll them up.
