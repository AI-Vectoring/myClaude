# Getting Started

## Requirements

- Debian/Ubuntu Linux
- `git` and `gh` (GitHub CLI) installed and authenticated
- `sudo` access for installing to `/usr/local/bin/`

## Install

```bash
git clone git@github.com:AI-Vectoring/myClaude.git ~/git/myClaude
~/git/myClaude/install.sh
```

The installer will:
- Set `MYCLAUDE_HOME` in `myClaude.conf` to your repo location
- Install `myClaude` to `/usr/local/bin/`
- Install `jq` if not already present
- Create `~/git/` if it doesn't exist

## First scan

```bash
myClaude scan
```

This shows all repos under your git root and their CLAUDE.md status. On first run it creates a baseline state snapshot.

## Create a new repo

```bash
myClaude newRepo my-project
myClaude newRepo --public my-public-project
```

This creates the GitHub repo, clones it to `~/git/`, creates `myClaude/repos/my-project/CLAUDE.md`, and symlinks it into the repo.

## Repair broken symlinks

After a plugin update or tool reinstall may overwrite a symlink:

```bash
myClaude repair
```

## Change your git root

If your repos live somewhere other than `~/git/`:

```bash
myClaude setRoot /path/to/your/repos
```

## Global CLAUDE.md

`~/.claude/CLAUDE.md` is symlinked to `myClaude/CLAUDE.md`. Edit it directly in the repo — changes take effect immediately.
