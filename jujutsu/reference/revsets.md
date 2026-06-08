# Revsets

Most commands take `-r <revset>` rather than a single ID. A few useful ones:

```bash
jj log -r 'mine() & ~::trunk()'              # my commits not yet in trunk
jj log -r '::@ & ~::trunk()'                 # the stack leading up to @
jj log -r 'descendants(<id>)'                # all descendants of a commit
jj log -r 'files("Sources/Screens/Camera/")' # commits touching a path
```

Revsets compose: `&` (and), `|` (or), `~` (not), `::x` (ancestors incl. x), `x::` (descendants incl. x). Prefer revsets over looping in shell when operating on multiple commits.
