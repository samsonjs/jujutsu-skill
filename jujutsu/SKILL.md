---
name: jujutsu
description: "**REQUIRED** - Always activate FIRST on any git/VCS operations (commit, status, branch, push, etc.), especially when HEAD is detached. If `.jj/` exists -> this is a Jujutsu (jj) repo - git commands will corrupt data. Essential git safety instructions inside. DO NOT IGNORE."
allowed-tools: Bash(jj *)
---

# Jujutsu (jj) Version Control System

Jujutsu is a Git-compatible VCS with mutable changes and automatic rebasing. This file is the core loop you'll use constantly. For the long tail, the `reference/` directory in this skill has one file per task — read only the one you need when that operation comes up (see the table near the end). Don't guess at those commands from memory; the reference exists because the details bite.

**Tested with jj v0.40.0** — commands may differ in other versions.

## Safety First

- **If `.jj/` exists, this is a jj repo. Do NOT run state-changing git commands** (`git commit`, `git checkout`, `git reset`, `git rebase`) — they corrupt jj's view and lose work. Use jj for all mutations. Read-only git (`git log`, `git diff`, `git show`, `git bisect`) is fine; run `jj st` afterward so jj re-imports state.
- **Push only when the user explicitly asks**, and only a change that's the right one, refined, and atomic.

## Think in jj, Not in Git

The user works in jj and thinks in jj — so should you. The failure mode is narrating in git terms ("amend the commit", "the branch", "is HEAD pushed?"). Use git-by-analogy to get oriented, then drop the analogy and reason in jj's own model.

- **The working copy is a change, always.** No staging, no "committing", no "amending". Editing files just updates the change at `@`. This is not an event — never narrate it ("jj auto-amended the commit"). The user isn't thinking about commits 99% of the time; neither should you.
- **Refer to work by what it is, not by SHAs.** "The VNC change" or "the change at `@`", not "commit 3c52cf9b" or "HEAD". Reach for commit IDs only when pointing at a specific historical snapshot.
- **Bookmarks are incidental labels for pushing, not branches you live on.** You work on a change; a bookmark may happen to point at it when it's time to push.
- **An empty `@` on top is normal.** After `jj squash` or `jj git push`, jj leaves a fresh empty `@`. That's the expected resting state, not a problem to fix. Don't reflexively abandon it — jj just recreates one whenever you're sitting on top of an immutable change anyway. Only abandon an empty change if it has grown children (work stacked on top of it) that you want collapsed.

**Vocabulary:** "change" not "commit"; "describe a change" not "make a commit"; "the change at `@`" not "HEAD"; "point a bookmark at" not "create a branch". Use git vocabulary only when the user does, or when explaining the git-interop layer itself.

## Agent Environment Rules

1. **Always use `-m`** to provide messages inline; editor-based commands fail non-interactively.

```bash
jj desc -m "message"      # NOT: jj desc
jj new -m "message"       # NOT: jj new && jj desc -m "..."
jj squash -m "message"    # NOT: jj squash (opens editor when both descriptions are non-empty)
```

2. **For multi-line or special-character messages, use `--stdin`** to dodge shell quoting:

```bash
printf '%s\n' "Subject line" "" "Body with \"quotes\" and \$vars." | jj desc --stdin
```

3. **Verify mutations with `jj st`** after `squash`, `abandon`, `rebase`, `restore`.
4. **Avoid every `-i` / `--interactive` flag** (`squash -i`, `split -i`, `commit -i`, bare `resolve`) — they open a TUI and hang agents.
5. **Pass `--git` to anything that renders a diff** (`jj diff`, `jj show`, `jj log -p`, `jj evolog -p`, `jj interdiff`). The default difftastic output relies on terminal colors that don't survive into tool output.

## Core Concepts

- **The working copy is a change** (referenced as `@`). Edits are auto-snapshotted into it on any jj command. No staging area, no `jj commit`.
- **Changes are mutable** — described, redescribed, split, squashed, rebased, abandoned freely. You don't have to get a change right up front. This is what makes the scratchpad loop work.
- **Change ID vs commit ID.** A change ID (`tqpwlqmp`) is a stable identifier for the *idea* of the change; it survives squash/rebase/redescribe. A commit ID (`3ccf7581`) is a content hash for one snapshot and changes whenever content does. **Reference things by change ID** almost always; commit IDs are for pointing at a specific historical snapshot (see `jj evolog`).

## The Inner Loop: Scratchpad + Squash

The idiomatic jj loop is layered. Two changes are in play:

- **Parent**: the change you'll eventually push. Has a description.
- **`@` (scratchpad)**: an anonymous child on top, no description. Like git's index — a place to iterate, run tests, undo. Ends up one of three ways: folded into the parent, promoted into its own change, or abandoned.

```bash
jj new -m "Add user authentication"   # parent — what you're shipping
jj new                                # scratchpad — no message
# edit, test, repeat
jj diff --git                         # review the scratchpad
jj squash                             # fold into parent; fresh empty @ on top
# OR
jj desc -m "message" && jj new        # promote to its own change; fresh scratchpad on top of that
# OR
jj abandon                            # throw the scratchpad away; back on parent
```

Which one depends on whether the scratchpad's content is *part of* the parent's idea or a *distinct* one — and this genuinely varies by context, including for the user themselves. Some starting defaults:

- **Squash** when it's a continuation — a fix, a missing piece, cleanup of the same change. The scratchpad has no value as its own unit; folding it in keeps history clean. Squash doesn't have to target the immediate parent — `jj squash --into <id>` sends it to whichever ancestor it actually belongs to, if the change stack represents discrete pieces of work rather than one growing blob.
- **Promote** by default when the work is unrelated to what you're currently on, even if trivial (an unrelated typo fix found mid-feature gets its own change, not folded into the feature). Also promote for a meaningful checkpoint worth keeping addressable on its own — a different approach you're trying, a step in exploratory work you might want to look back at, cherry-pick, drop, or reorder independently later.
- **Abandon** when it added nothing worth keeping at all — a dead end with no future value, even as a record.

Whether a finished stack of checkpoints later gets squashed down, squashed into a specific ancestor, or left alone to show its evolution is not a fixed rule — it depends on specifics that live in the user's head (is this shipping as one PR or a stack of them? does the history itself matter later? is it already pushed?). **When it's not obvious which outcome fits, ask instead of guessing** — don't reflexively squash just because a scratchpad is "done."

After `jj squash` you're back on a fresh empty `@`, ready for the next iteration. Run as many scratchpad → squash cycles as you want; each means "I made progress, keep it." The parent's commit ID changes on every squash, but its **change ID is stable** — that's why you reference it by change ID.

**When the scratchpad is overkill**: tiny one-shot work (typo, single-line tweak) — describe `@` directly and edit, skip the layer. Its value is throwing away dead-ends without polluting the parent; no risk of dead-ends, no need for the layer.

For parallel experiments, stacking, and moving between changes, see `reference/inspect.md`.

## Refining a Change Before Pushing

Mutability is the point — refine freely. Before a change leaves your machine:

1. **Review** with `jj show <change-id>` or `jj diff -r <change-id> --git`
2. **Atomic?** If it spans two ideas, `jj split <paths>` or move pieces with `jj squash --from / --into`
3. **Message clear?** Imperative verb phrase, sentence case, no full stop: "Verb object". `jj desc -m "..."` (or `jj metaedit -m "..."` to change just the description without touching the snapshot)
4. **Unrelated changes leaked in?** `jj restore <paths>` to drop them
5. **Belongs in an ancestor?** `jj squash --into <id>` or `jj absorb`

(Details for split / squash / absorb / metaedit are in `reference/refine.md`.)

## Pushing Changes

**Default to one-shot push commands. Don't create bookmarks manually unless you have a reason to.** These two cover ~90% of pushes:

```bash
# Push @ with an auto-generated name (push-<change-id>). Use when you don't care
# about the remote branch name — most feature/PR work.
jj git push -c @

# Push @ under a name you choose. Use when the branch name matters (convention,
# ticket prefix, user asked for it).
jj git push --named feature/auth-fix=@
jj git push --named bug/1234=<change-id>
```

Both create the bookmark, push it, and set up tracking in one command — no prior `jj bookmark create` needed.

**Only fall back to `jj git push -b <name>` when the bookmark already exists** — typically updating a branch you pushed earlier. Bookmarks don't auto-advance, so move it first:

```bash
jj bookmark set my-feature -r @ -B    # -B because you're moving it forward
jj git push -b my-feature
```

Push safety checks, deletion pushes, bookmark tugging, and `--dry-run`/`--tracked` are in `reference/bookmarks.md` and `reference/git.md`.

## When to Reach for reference/

Read only the file you need:

| You need to... | File |
|----------------|------|
| Inspect history, files-at-rev, blame, move `@`, stack, parallel experiments | `reference/inspect.md` |
| Split, absorb, abandon, revert, duplicate, metaedit, fix, rebase, restore files, or you hit "Commit X is immutable" | `reference/refine.md` |
| Recover mangled work (evolog, undo, op log/restore/revert) | `reference/recover.md` |
| Create/move/delete/forget/tug bookmarks | `reference/bookmarks.md` |
| Clone/init, colocated repos, push safety details | `reference/git.md` |
| Resolve conflicts (jj's markers ≠ git's) | `reference/conflicts.md` |
| Write revsets (`-r '...'`) | `reference/revsets.md` |

## Best Practices Summary

1. **Layer your work**: parent change with a description, anonymous scratchpad on top. Squash when it's the same idea, promote to its own change when it's distinct, abandon when it's a dead end — ask when it's not obvious which.
2. **Reference by change ID**: stable across rewrites.
3. **Refine before pushing, not before coding**: iterate, then clean up.
4. **Push with `-c @` or `--named`**: don't bother creating bookmarks manually for normal PR work.
5. **Trust the op log**: `jj op log` + `jj op restore` is your safety net. Almost nothing is truly lost.
