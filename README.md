# myClaude

A personal CLI for managing Claude Code configuration across all your git repositories.

## What it does

- Creates new GitHub repos with CLAUDE.md wired up automatically
- Keeps all your CLAUDE.md files in one place (`myClaude/repos/`) via symlinks
- Scans your git root for repos and reports their Claude configuration status
- Repairs broken symlinks when plugins or tools overwrite them

## Commands

```
myClaude newRepo <name>   Create a new repo with CLAUDE.md linked
myClaude scan             Show status of all repos
myClaude repair           Fix broken or missing CLAUDE.md symlinks
myClaude setRoot <path>   Change the git root directory (default: ~/git)
```

## Overriding Claude Code files

Claude Code automatically reads files from various locations — plugin directories, config folders, hook scripts — and loads them into your context every session. You don't always want everything a plugin or tool ships.

myClaude lets you take ownership of any such file by replacing it with a symlink to a version you control inside this repo. Edit the file here; the change takes effect immediately. Run `myClaude repair` if an update overwrites the symlink.

### Example: superpowers plugin CLAUDE.md

The superpowers plugin ships a `CLAUDE.md` containing contributor guidelines for submitting PRs to the superpowers repo. This loads into your context every session whether you're contributing to superpowers or not.

myClaude symlinks `~/.claude/plugins/cache/.../superpowers/CLAUDE.md` to `myClaude/plugins/superpowers/CLAUDE.md`, so you can strip out the noise and keep only what's relevant to your workflow.

## Installation

```bash
git clone git@github.com:AI-Vectoring/myClaude.git ~/git/myClaude
~/git/myClaude/install.sh
```

See [getting-started.md](getting-started.md) for a full walkthrough.
