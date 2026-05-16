# rcall

Recursive text search in file and directory names and file content — fast, minimal, script-friendly.

```
rcall config src/
rcall --case-sensitive Error logs/ src/
rcall --ignore ".venv,target" imports .
```

## What it does

`rcall` walks a directory tree and reports every file or directory whose **name** contains the search term, and every file whose **content** contains it. Output is one match per line, structured for scripting.

It skips symlinked directories (no infinite loops), skips binary files (detected by byte probe), and warns about unreadable files on stderr — without stopping the search.

## Install

Requires [Nim](https://nim-lang.org/) 2.0 or later.

```sh
git clone https://github.com/isuzano/rcall
cd rcall
./scripts/build.sh
```

This produces a single binary `rcall` in the project root. Move it somewhere on your `$PATH`.

## Usage

```
rcall TEXT [PATH ...]
rcall [--ignore list] [--no-default-ignore] [--ignore-case|--case-sensitive] TEXT [PATH ...]
rcall -h | --help
```

If no `PATH` is given, the search starts from the current directory. Multiple paths are accepted and deduplicated automatically.

Use `--` to search for text that starts with a hyphen:

```sh
rcall -- --my-flag src/
```

### Options

| Flag | Description |
|---|---|
| `--ignore list` | Comma-separated directory names to skip |
| `--no-default-ignore` | Disable built-in ignored directories |
| `--ignore-case` | Case-insensitive matching (default) |
| `--case-sensitive` | Exact case matching |
| `-h`, `--help` | Show help and exit |

### Default ignored directories

`.git`, `node_modules`, `build`, `dist`, `.cache`

Disable them with `--no-default-ignore`. Add your own with `--ignore`.

## Output

Every match is a tab-separated line on stdout:

```
path    line    kind
```

- `line` is `0` for name-based matches, or the line number for content matches
- `kind` is `name` or `content`

```sh
# Extract only paths
rcall config src/ | cut -f1

# Show only content matches with line numbers
rcall TODO . | awk -F'\t' '$3 == "content" { print $1 ":" $2 }'

# Count matches
rcall error logs/ | wc -l
```

Warnings go to stderr. The search continues past unreadable files and invalid paths.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | At least one match found |
| `1` | No matches found |
| `2` | Usage or argument error |

This follows the `grep` convention, making `rcall` composable in shell pipelines and `if` conditions.

## Design

- No dependencies beyond the Nim standard library
- Reads files line by line — no full file loaded into memory
- Binary detection scans the first 4 KB (null byte → binary; >10% control characters → binary)
- `termLower` computed once per run, not per line
- Deduplication across overlapping roots via a typed hash set
- Deterministic output: sorted by path, then line number, then kind

See [docs/DESIGN.md](docs/DESIGN.md) for module-level documentation.

## License

MIT — see [LICENSE](LICENSE).
