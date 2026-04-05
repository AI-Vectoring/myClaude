# Implementing myClaude

For developers extending or forking myClaude.

## Structure

```
myClaude/
├── myClaude.sh          # Dispatcher — routes subcommands
├── myClaude.conf        # Configuration (GIT_ROOT, MYCLAUDE_HOME)
├── install.sh           # Bootstrap installer
├── CLAUDE.md            # Global Claude Code rules (symlinked from ~/.claude/CLAUDE.md)
├── commands/            # One script per subcommand
│   ├── newRepo.sh
│   ├── scan.sh
│   ├── repair.sh
│   └── setRoot.sh
├── repos/               # Per-repo CLAUDE.md files (symlinked into each repo)
│   └── <repo-name>/
│       └── CLAUDE.md
├── plugins/             # Plugin-specific CLAUDE.md overrides
│   └── superpowers/
│       └── CLAUDE.md
└── .flags/              # Per-repo flags (e.g. do-not-include)
    └── <repo-name>/
        └── do-not-include
```

## Adding a command

1. Create `commands/<name>.sh` — handle `--help`, source `myClaude.conf` at the top
2. Add a `<name>)` case to `myClaude.sh` dispatching to `$MYCLAUDE_HOME/commands/<name>.sh`
3. Add the command to the help text in `myClaude.sh`
4. Run `install.sh` to update `/usr/local/bin/myClaude`

## Configuration

All scripts source `myClaude.conf` for:
- `GIT_ROOT` — root directory containing git repos
- `MYCLAUDE_HOME` — absolute path to the myClaude repo

`setRoot.sh` updates `GIT_ROOT`. `install.sh` updates `MYCLAUDE_HOME`.

## Symlink model

- `~/.claude/CLAUDE.md` → `myClaude/CLAUDE.md`
- `~/git/<repo>/CLAUDE.md` → `myClaude/repos/<repo>/CLAUDE.md`
- Plugin overrides: `~/.claude/plugins/cache/.../CLAUDE.md` → `myClaude/plugins/.../CLAUDE.md`

Symlinks are one-way pointers. Editing the file works from either side. Overwrites (installers, git checkout) replace the symlink with a new file — run `myClaude repair` to restore.

## State files

`scan.sh` writes `.state.json` and `.state.prev.json` to `MYCLAUDE_HOME`. These are gitignored — local only.
