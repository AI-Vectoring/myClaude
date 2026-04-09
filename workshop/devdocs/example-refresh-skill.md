# Example: The /refresh skill

A worked example of implementing a personal standalone skill.

## The problem

Claude Code loads your `CLAUDE.md` rules at session start but drifts from them as the conversation grows. There is no built-in way to re-read and reaffirm the rules mid-session.

## Why a standalone skill

- Personal workflow, not project-specific
- Short invocation name `/refresh` preferred over `/myClaude:refresh`
- No supporting files needed
- Should be available across all projects

A standalone personal skill at `~/.claude/skills/refresh/` is the right fit. See [skills-commands-plugins.md](skills-commands-plugins.md) for the decision framework.

## Implementation

File: `~/.claude/skills/refresh/SKILL.md` (symlinked from `myClaude/skills/refresh/SKILL.md`)

```yaml
---
description: Re-read CLAUDE.md rules and reaffirm them for this session
---

Based on $ARGUMENTS, read and restate the rules from the following CLAUDE.md files,
confirming you will follow them for the rest of this session:

- no argument or "global": read ~/.claude/CLAUDE.md only
- "all": read ~/.claude/CLAUDE.md, the CLAUDE.md at the project root, and the CLAUDE.md
  in the current working directory
- "project": read the CLAUDE.md at the project root only
- "dir": read the CLAUDE.md in the current working directory only

For each file read, list the rules found. If a file does not exist, say so and skip it.
```

## Usage

```
/refresh              # re-reads global rules only
/refresh all          # re-reads global + project + current directory
/refresh project      # re-reads project root CLAUDE.md only
/refresh dir          # re-reads current directory CLAUDE.md only
```

## Symlinking

The skill lives in `myClaude/skills/refresh/SKILL.md` and is symlinked to `~/.claude/skills/refresh/SKILL.md` by `install.sh`. This keeps it version-controlled in myClaude while being discoverable by Claude Code.

```bash
mkdir -p ~/.claude/skills/refresh
ln -sf ~/git/myClaude/skills/refresh/SKILL.md ~/.claude/skills/refresh/SKILL.md
```

## Key gotcha

Standalone skills require a **session restart** to be discovered. `/reload-plugins` only works for plugin skills.
