# Git Integration

Clone/init, colocated repos, and the push safety details beyond the two one-shot commands in SKILL.md → Pushing.

## Working with existing git repos

```bash
jj git clone <url>                    # clone a git repository
jj git init --colocate                # initialize jj in an existing git repo
```

## Colocated repos (`.jj/` and `.git/` both present)

Both tools can read the repo, but **prefer jj for all state-changing operations**. Mixing `git checkout`/`commit`/`reset` with jj's view of the working copy loses work.

```bash
jj new <bookmark-or-rev>     # fresh change on top of a ref (≈ git checkout + commit)
jj edit <bookmark-or-rev>    # jump @ onto that change directly
jj git fetch                 # pull remote changes and update tracked bookmarks
```

Safe to use git for read-only inspection (`git log`, `git diff`, `git show`) or operations jj doesn't cover (e.g. `git bisect`). After any raw git operation, run `jj st` so jj re-imports the state.

## Push safety checks

jj runs these automatically (mirroring `git push --force-with-lease`):

- The remote is only updated if it matches what jj last fetched. Run `jj git fetch` if a push is rejected for remote-moved-forward.
- Pushes are refused when the commit has an empty description, contains conflicts, is private (`git.private-commits`), or is a new merge commit introducing unpushed work. `jj show <rev>` usually tells you which. Override with `--allow-empty-description` or `--allow-private` only when you mean it.

## Other push flags

```bash
jj git push --dry-run -c @            # preview without pushing
jj git push --tracked                 # push every tracked bookmark whose @-position moved
```
