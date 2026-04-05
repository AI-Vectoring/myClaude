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

## Overriding Claude Code files

Claude Code reads files automatically from plugin directories, config folders, and hook scripts. Not all of it is useful — some plugins ship content that loads into your context every session regardless of relevance.

To override any such file:

1. Copy it to the appropriate path under `myClaude/` (e.g. `plugins/superpowers/CLAUDE.md`)
2. Replace the original with a symlink pointing to your copy
3. Edit your copy — changes take effect immediately
4. If a plugin update overwrites the symlink, run `myClaude repair`

### Example: stripping the superpowers contributor guidelines

The superpowers plugin's `CLAUDE.md` loads PR submission rules into your context every session. To neutralize it:

```bash
# Already done if you cloned myClaude — the symlink is in place.
# Just edit the file to keep only what you need:
nano ~/git/myClaude/plugins/superpowers/CLAUDE.md
```

## Global CLAUDE.md

`~/.claude/CLAUDE.md` is symlinked to `myClaude/CLAUDE.md`. Edit it directly in the repo — changes take effect immediately.
