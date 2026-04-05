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

## Installation

```bash
git clone git@github.com:AI-Vectoring/myClaude.git ~/git/myClaude
~/git/myClaude/install.sh
```

See [getting-started.md](getting-started.md) for a full walkthrough.
