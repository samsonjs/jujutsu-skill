# Recovery

Getting work back after a mangled squash/rebase/abandon. Almost nothing in jj is truly lost — it's just unreachable from the current op. Reminder: pass `--git` to any patch output.

## Seeing how a change evolved

`jj evolog` shows every prior version of a change (pre-rebase, pre-squash, etc.) — the real recovery tool when you've mangled a commit:

```bash
jj evolog                 # history of @
jj evolog -r <change-id>  # history of a specific change
jj evolog -p --git        # with patches for each version
```

## Comparing two versions of a change

`jj interdiff` compares what two revisions *do* (their patches), not file contents. Canonical use is checking what's changed locally since you last pushed:

```bash
jj interdiff --from push-xyz@origin --to push-xyz --git
```

## Undoing operations

```bash
jj undo                   # reverse the last jj operation
```

_**NOTE**: Don't run `jj op undo` — that command does not exist._

`jj undo` only reverses the immediately prior op; after several operations it gets confusing. The operation log is far more powerful:

```bash
jj op log                 # every operation jj has performed, with IDs
jj op restore <op-id>     # jump the repo back to the state at an operation (time machine)
jj op show <op-id>        # show what changed in one operation
jj op revert <op-id>      # invert a single mid-history op, leaving later ops in place
                          # (contrast op restore, which rewinds everything)
```

This is the real safety net — `jj op log` + `jj op restore` recovers almost any mistake.
