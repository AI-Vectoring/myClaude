# CLI Commands

All commands are run as `myClaude <command> [options]`. Run `myClaude --help` for a summary or `myClaude <command> --help` for command-specific help.

---

## newRepo

Creates a GitHub repo, clones it locally, and wires up a managed CLAUDE.md symlink — all in one step.

```
myClaude newRepo [-p|--public] <repo-name>
```

**What it does:**
1. Calls `gh repo create` to create the repo on GitHub (private by default)
2. Clones it into your `GIT_ROOT` (e.g. `~/git/<repo-name>`)
3. Creates `myClaude/custom/repos/<repo-name>/CLAUDE.md` — your editable source file
4. Symlinks `<repo>/CLAUDE.md` → that source file

**Options:**
- `-p`, `--public` — create a public repo instead of private

**Example:**
```bash
myClaude newRepo my-project           # private repo
myClaude newRepo --public my-library  # public repo
```

After creation, edit `custom/repos/my-project/CLAUDE.md` to add repo-specific rules. The symlink means Claude Code reads it directly from the repo.

---

## scan

Shows the CLAUDE.md status of every repo under your git root, and what changed since the last scan.

```
myClaude scan
```

**Output columns:**

| Column    | Values                                                         |
|-----------|----------------------------------------------------------------|
| REPO      | Directory name of the repo                                     |
| CLAUDE.MD | `ok` — symlink in place and working                            |
|           | `not linked` — CLAUDE.md exists but isn't a symlink into myClaude |
|           | `missing` — no CLAUDE.md at all                                |
| FLAGS     | `excluded` — marked do-not-include, ignored by all commands    |

**Change detection:**

Each run saves a state snapshot. On subsequent runs, scan compares against the previous snapshot and reports:
- **New** — repos that appeared since last scan
- **Removed** — repos that disappeared
- **Changed** — repos whose status changed (e.g. symlink broke, CLAUDE.md added)

On first run, it creates the baseline and reports no changes.

---

## repair

Fixes CLAUDE.md symlinks across all your repos. Run this after a plugin update, tool reinstall, or anything else that might overwrite a symlink with a regular file.

```
myClaude repair
```

**What it does for each repo:**
1. Skips repos flagged as `do-not-include`
2. Checks if `<repo>/CLAUDE.md` is a valid symlink pointing to `myClaude/custom/repos/<name>/CLAUDE.md`
3. If the source file doesn't exist in myClaude, creates it
4. Removes any broken symlink or plain file and re-creates the symlink

**Output:**
- Lists each repo it creates a source file for or repairs a link for
- Ends with a count of repaired and skipped repos

---

## setRoot

Changes where myClaude looks for your git repos.

```
myClaude setRoot <path>
```

**What it does:**
- Validates that `<path>` exists
- Rewrites `GIT_ROOT` in `myClaude.conf`

All commands (`scan`, `repair`, `newRepo`) use `GIT_ROOT` to find repos. Default is `~/git`.

**Example:**
```bash
myClaude setRoot /home/user/projects
```

---

## Excluding a repo

To make myClaude ignore a repo across all commands:

```bash
mkdir -p ~/git/myClaude/.flags/<repo-name>
touch ~/git/myClaude/.flags/<repo-name>/do-not-include
```

The repo will show as `excluded` in scan output and will be skipped by repair and newRepo.
