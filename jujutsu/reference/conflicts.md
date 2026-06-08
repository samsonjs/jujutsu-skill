# Handling Conflicts

jj allows committing conflicts — resolve them later:

```bash
jj st                     # shows conflicts
jj resolve --list         # list conflicted paths non-interactively
```

**jj's conflict markers are NOT git's markers.** Editing them like git markers produces a garbage resolution. jj uses a diff-style format that can represent 3-way and N-way conflicts:

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

To resolve: delete the entire `<<<<<<< ... >>>>>>>` block and replace it with the final merged content. The `%%%%%%%` section is a diff (base → side 1); the `+++++++` section is the literal content of side 2. Reconstruct the intended merged content from those hints.

After editing:

```bash
jj st                     # verify no more conflicts
jj resolve --list         # should report nothing
```

Avoid `jj resolve` without args (launches an interactive merge tool). To use a tool non-interactively: `jj resolve --tool <name> <path>`.
