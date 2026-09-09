# Workspaces

A workspace is a working copy attached to the repo. One repo can have several, each with its own working directory and its own working-copy commit, all sharing the same changes, operations, and bookmarks. This is jj's answer to `git worktree`.

You rarely need one. Reach for a workspace when something slow needs to run against one revision while you keep editing at another — a long build, a full test suite. If you only need to *look* at another revision, don't add a workspace; inspect it in place (see `reference/inspect.md`).

```bash
jj workspace add ../my-tests                        # name defaults to the basename, "my-tests"
jj workspace add --name tests -r main ../my-tests   # explicit name, new change on top of main
jj workspace list
jj workspace root --name tests                      # where another workspace lives on disk
jj workspace rename new-name                        # renames the current workspace
jj workspace forget tests                           # stop tracking it; files stay on disk
```

In `jj log`, each workspace's working copy shows up as `<name>@` rather than a bare `@`.

## What `-r` actually does

`-r` supplies the **parents** of the new workspace's working-copy commit. It is not a branch to check out. `jj workspace add -r main ../x` creates a fresh empty change whose parent is `main`, so you start clean on top of `main` rather than looking at `main` itself.

With no `-r`, the new working-copy commit inherits the parents of the current `@`. It starts as a sibling of what you're working on, not a copy of it. Passing several revisions makes the new change a merge of all of them.

## Semantics that bite

- **Isolation by default.** A new workspace gets its own fresh empty change. Workspaces don't share `@` unless you force it, and on-disk files are never mirrored between them.
- **Propagation happens at command boundaries.** Every jj command snapshots the current workspace and reads the op log, so it sees changes and bookmark moves made from other workspaces. There is no filesystem watcher and nothing syncs between commands.
- **Stale working copies.** If another workspace rewrites this one's `@` — a `squash`, `rebase`, or `abandon` that touches it — jj refuses to run here until you run `jj workspace update-stale`. Same recovery path when a command was interrupted partway through updating the working copy.
- **Sharing `@` is sharp.** `jj edit <id>` will point two workspaces at the same change without warning. When one rewrites it the other goes stale, and if that one had un-snapshotted edits, `update-stale` preserves them as a divergent commit: same change ID, rendered `xyz??` in `jj log`. Untangling that is manual work.

## Agent rules

1. **Check `jj workspace list` before `jj edit`.** Editing a change that another workspace already has as its `@` is the main cause of accidental divergence.
2. **Pair directory deletion with `jj workspace forget <name>`.** Removing the directory alone leaves the repo tracking a workspace that isn't there.
3. **Name the workspace you're forgetting.** Bare `jj workspace forget` forgets the *current* one, which is seldom what you meant.
4. **On a stale-working-copy error, run `jj workspace update-stale` in that workspace**, then re-check `jj st`. It's the intended fix, not a sign anything is lost.

Anything beyond this, see the [official docs](https://docs.jj-vcs.dev/latest/working-copy/#workspaces).
