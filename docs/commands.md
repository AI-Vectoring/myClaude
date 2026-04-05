# Commands

> Official documentation: https://code.claude.com/docs/en/commands

Commands are the legacy form of skills. A `.md` file in a `commands/` directory creates a `/slash-command`. They still work and support the same frontmatter as skills, but skills are the recommended approach going forward.

## Directory structure

```
~/.claude/commands/<command-name>.md       # Personal, available across all projects
.claude/commands/<command-name>.md         # Project-level, this project only
<plugin>/commands/<command-name>.md        # Plugin-scoped
```

## Format

Same as a skill's `SKILL.md` — frontmatter + markdown instructions:

```yaml
---
description: What this command does
---

Your instructions here. Use $ARGUMENTS for user input.
```

## Relationship to skills

- A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work identically
- If a skill and a command share the same name, the skill takes precedence
- Commands do not support supporting files (templates, scripts) alongside them — that's the main thing skills add

## When to use commands over skills

Only when you want a single flat file with no supporting assets and don't need the extra frontmatter features. Otherwise use skills.
