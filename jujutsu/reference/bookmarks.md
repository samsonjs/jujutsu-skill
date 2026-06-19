# Working with Bookmarks (Branches)

You usually don't need bookmarks. `jj git push -c @` and `jj git push --named name=@` create-and-push in one step (see SKILL.md → Pushing). Reach for these only when a named local ref earns its keep — updating an already-pushed branch, sharing a ref name across commands, or stacked-PR work.

```bash
jj bookmark set my-feature -r @       # create or move; -B to move backwards/sideways
jj bookmark list
jj bookmark rename old new
jj bookmark track my-feature@origin   # start tracking a remote bookmark
```

## Delete vs forget

```bash
jj bookmark delete my-feature         # marks for deletion; propagates to remote on next push
jj bookmark forget my-feature         # drops local only; remote bookmark becomes untracked
```

Use `forget` when undoing a local mistake. Use `delete` only when you actually want the remote branch gone.

**Pushing a deleted bookmark**: `jj bookmark delete` only marks it locally. To propagate, push by name:

```bash
jj bookmark delete my-feature
jj git push -b my-feature             # sends the deletion to the remote
```

`jj git push --deleted` (no argument) pushes ALL pending bookmark deletions at once. There is **no `--deleted <name>` form** — it's a boolean flag, not a parameter.

## Tugging bookmarks forward

Bookmarks don't auto-advance when you squash or rebase. After iterating, a bookmark may point at an older version and need dragging up.

**When you know the bookmark name** — set it directly:

```bash
jj bookmark set my-feature -r @-      # or whatever revision it should point at
jj bookmark set main -r @-            # -B only needed when moving backwards/sideways
```

**When you just want to drag the closest bookmark up to your work** — `jj bookmark advance` (aka `jj b a`) is the purpose-built command. It moves the nearest ancestor bookmark forward without you naming it:

```bash
jj bookmark advance                   # advance the closest bookmark toward @
```

Where it lands is controlled by the `revsets.bookmark-advance-to` config, which can be set to skip an empty scratchpad on top and land on the real work instead. It defaults to `@`.

**When you need full control over source and destination** — drive the move with an explicit revset:

```bash
jj bookmark move --from "heads(::@ & bookmarks())" --to @
```

The revset `heads(::@ & bookmarks())` finds the closest bookmark ancestor of `@`. Reach for named `bookmark set` first when you already know what you're moving, `jj bookmark advance` when you just want the nearest one tugged up.
