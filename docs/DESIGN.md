# DESIGN

## Summary

`rcall` is a command-line tool for recursive text matching in file/directory names
and file content.

## Code Organization

- `src/rcall.nim`: minimal entrypoint
- `src/rcall/app.nim`: coordinates parsing, execution, and exit code
- `src/rcall/cli.nim`: argument parser
- `src/rcall/walker.nim`: recursive traversal and matching
- `src/rcall/output.nim`: stdout/stderr rendering
- `src/rcall/errors.nim`: application error type
- `src/rcall/types.nim`: core shared types

## Principles

- clear module boundaries
- short and direct messages
- deterministic output
- low operational complexity
- user-controlled ignore behavior (`--ignore`, `--no-default-ignore`)
