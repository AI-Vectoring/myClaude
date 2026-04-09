# Project structure

Reference for what every file in myClaude does.

## Source files

### `cli/myClaude.sh`
CLI entry point. Parses the first argument and hands off to the right script in `cli/`. Install it with `install.sh` and call it as `myClaude <subcommand>`.

### `myClaude.conf`
Stores the two paths everything depends on: where your git repos live (`GIT_ROOT`) and where myClaude is installed (`MYCLAUDE_HOME`). Sourced by every script at startup.

### `install.sh`
Gets myClaude working on a new machine: writes real paths into `myClaude.conf`, drops the binary in `/usr/local/bin/`, and links the `/refresh` skill into `~/.claude/skills/`.

### `cli/newRepo.sh`
Creates a new repo end-to-end — GitHub repo, local clone, and a managed `CLAUDE.md` symlink — in one command. Accepts `-p`/`--public`; defaults to private.

### `cli/scan.sh`
Tells you what state all your repos are in and what changed since last time you looked. Writes `.state.json` and `.state.prev.json` to `MYCLAUDE_HOME`; both are gitignored.

### `cli/repair.sh`
Fixes `CLAUDE.md` symlinks that got broken or replaced by plugin updates or reinstalls. Skips repos marked with a `.flags/<name>/do-not-include` file.

### `cli/setRoot.sh`
Changes where myClaude looks for your git repos by rewriting `GIT_ROOT` in `myClaude.conf`. Validates the new path exists before writing.

### `CLAUDE.md`
Your global Claude rules, version-controlled here and symlinked to `~/.claude/CLAUDE.md` where Claude Code reads them.

### `repos/example-repo/CLAUDE.md`
Starter template showing what a repo-specific `CLAUDE.md` looks like. Committed so new installs have a working example.

### `plugins/superpowers/CLAUDE.md`
Blanks out the superpowers plugin's `CLAUDE.md` so its contributor guidelines don't pollute your context. Symlinked over the plugin's installed copy.

### `plugins/superpowers/AGENTS.md`
Same override pattern as `CLAUDE.md`, for harnesses that read `AGENTS.md` instead.

### `plugins/superpowers/GEMINI.md`
Wires up the superpowers skill references for the Gemini harness. Points to `skills/using-superpowers/SKILL.md` and `references/gemini-tools.md`.

### `skills/refresh/SKILL.md`
The `/refresh` skill. Re-reads one or more `CLAUDE.md` files mid-session and reaffirms the rules without restarting. Accepts `global`, `all`, `project`, or `dir` as arguments.

### `custom/defaults`
Single setting: `includeCoAuthoredBy: false`. Turns off Claude's automatic Co-authored-by commit trailer.

### `.claude/settings.local.json`
Local session permissions for this repo. Whitelists `WebFetch(domain:docs.anthropic.com)` and `WebSearch` so Claude can fetch Anthropic docs without prompting.

### `.state.json` / `.state.prev.json`
Scan snapshots — JSON arrays of all repos with `has_claude`, `is_linked`, and `do_not_include` booleans. Gitignored; used only to show what changed between runs.

---

## Docs (`docs/`)

### `memory.md`
Full reference for both `CLAUDE.md` instruction memory and auto-memory. Covers load order, path-scoped rules, `@imports`, size limits, `claudeMdExcludes`, auto-dream, compaction survival, and PreCompact/PostCompact hooks.

### `statusline.md`
Concise setup reference for the Claude Code status line: how to add `statusLine` to settings, what JSON fields are available, and a one-liner test command.

### `status-command.md`
Exhaustive deep-dive on the status line. All JSON fields with descriptions, null/absent edge cases, script examples in Bash/Python/Node/PowerShell, caching advice, and a full troubleshooting table.

### `skills.md`
Skills format and frontmatter reference. Covers directory structure, `SKILL.md` format, invocation control flags, `$ARGUMENTS` syntax, and discovery behaviour.

### `commands.md`
Documents commands as the legacy form of skills — single `.md` files creating slash-commands. Notes they still work but skills are preferred; explains the skill-wins-on-name-conflict rule.

### `plugins.md`
Plugin directory structure and `plugin.json` manifest format. Covers skill namespacing, install methods, `CLAUDE.md`/`AGENTS.md` context pollution, and the `/reload-plugins` mechanism.

### `skills-commands-plugins.md`
Decision framework for choosing between skills, commands, and plugins. Includes a comparison table and documents the myClaude-specific approach of using standalone personal skills for short unnamespaced invocations.

### `example-refresh-skill.md`
Worked example of building `/refresh` as a standalone skill. Explains why it's not a command or plugin skill, shows the full `SKILL.md` content, and documents the symlink pattern used by `install.sh`.

### `permissions.md`
Permission system reference: allow/ask/deny evaluation order, tool specifier syntax for Bash/File/Web/MCP/Subagent, `defaultMode` options, and safety advice via the `update-config` skill.

### `structure.md` *(this file)*
What every file in myClaude does.
