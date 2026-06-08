# Refining Changes

Rearranging and rewriting changes: squash, split, absorb, abandon, revert, duplicate, metaedit, fix, rebase, restore. Plus the immutable-commit error you'll hit when you try to rewrite trunk. Reminders: always `-m`/`--stdin`, never `-i`, verify with `jj st`.

## Squashing

Move part of the current change into its parent, or between arbitrary changes:

```bash
jj squash                             # all changes into parent
jj squash --into <change-id>          # into a specific commit
jj squash --from <source-id> --into <dest-id>   # between two commits (neither need be @)
jj squash path/to/file.txt            # only specific paths
jj squash --keep-emptied              # keep source even if squashing empties it
```

If both source and destination have non-empty descriptions, `jj squash` prompts for the combined description in an editor. To avoid the prompt:

- **Prefer `-m "..."`** — always safe, you supply the final message explicitly.
- **`--use-destination-message`** keeps the destination's description and discards the source's. Only safe when the destination definitely has the real description. In the normal scratchpad workflow (`jj squash` no args) the destination is the parent `@-`, which is correct. But if source/destination are accidentally reversed and the destination has an empty description, this **silently discards the real message**. When in doubt, use `-m`.

## Splitting

`jj split` **without arguments** is interactive and hangs agents. But `jj split <paths>` works non-interactively — it splits the listed paths into the first of two changes:

```bash
jj split path/to/file.txt other/file.swift   # listed paths stay in @-, rest go to @
jj split -r <change-id> path/to/file.txt     # split a specific commit
jj split --parallel path/to/file.txt         # resulting commits become siblings, not parent/child
```

## Absorbing

Automatically fold each hunk into the ancestor change that last modified those lines:

```bash
jj absorb
```

## Abandoning

Remove a change entirely (descendants are rebased to its parent):

```bash
jj abandon <change-id>
jj abandon <change-id> --retain-bookmarks      # keep bookmarks (moved to parent)
jj abandon <change-id> --restore-descendants   # preserve descendants' file contents instead of
                                               # re-applying their diffs (avoids conflicts)
```

## Reverting (applying the inverse)

Unlike `git revert`, `jj revert` can insert the inverse commit anywhere:

```bash
jj revert -r <change-id> --insert-after @
jj revert -r <change-id> --insert-before <other-id>
```

## Duplicating (cherry-pick equivalent)

```bash
jj duplicate <change-id> --onto <dest>           # copy onto a different parent
jj duplicate <change-id> --insert-after <dest>   # copy into the middle of another branch
```

## Editing metadata without changing content

`jj metaedit` updates author, timestamp, or description without rewriting content:

```bash
jj metaedit -m "New message"               # description only
jj metaedit --update-author                # refresh author to configured user
jj metaedit --update-author-timestamp      # bump author date to now
```

## Applying formatters

`jj fix` runs configured code formatters over changed files and updates the changes containing them (and descendants):

```bash
jj fix                    # fix @ and its changed files
jj fix -s <change-id>     # fix a specific commit and its descendants
```

Requires `fix.tools.*` configured in `~/.config/jj/config.toml` first — without it, `jj fix` is a no-op. See `jj help -k config`.

## Rebasing

```bash
jj rebase -d <dest>                   # current commit + descendants onto a new parent
jj rebase -s <source> -d <dest>       # a specific commit + its descendants
jj rebase -r <change-id> -d <dest>    # only one commit (no descendants move)
jj rebase -b <source> -d <dest>       # entire branch (source back to common ancestor with dest)
```

`-d` can take multiple destinations to create a merge commit.

## Restoring files

```bash
jj restore                            # discard all working-copy changes (restore from parent)
jj restore path/to/file.txt           # discard changes to specific files
jj restore --from <change-id> path/to/file.txt   # restore files from a specific revision
```

## Immutable commits

Commits reachable from `trunk()` (typically `main`/`master` and anything merged into it) are **immutable** by default — `jj edit`, `abandon`, `squash`, and `rebase -r` on them fail with "Commit X is immutable."

This is intentional safety. The set is configured via `revset-aliases."immutable_heads()"` (usually `trunk()`). To genuinely rewrite public history (rare — usually wrong), pass `--ignore-immutable` on the specific command:

```bash
jj --ignore-immutable rebase -r <immutable-id> -d <dest>
```

When you see the error, the right reaction is almost always "make a new commit on top" rather than bypass. Only reach for `--ignore-immutable` with explicit user confirmation.
