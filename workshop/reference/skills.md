# Skills

> Official documentation: https://code.claude.com/docs/en/skills

Skills extend what Claude can do. Create a `SKILL.md` file with instructions and Claude adds it to its toolkit. You can invoke a skill directly with `/skill-name`, or Claude can load it automatically when relevant.

## Directory structure

```
~/.claude/skills/<skill-name>/SKILL.md     # Personal, available across all projects
.claude/skills/<skill-name>/SKILL.md       # Project-level, this project only
<plugin>/skills/<skill-name>/SKILL.md      # Plugin-scoped, namespaced as /plugin:skill
```

Each skill is a directory with `SKILL.md` as the required entrypoint. Supporting files (templates, examples, scripts) can live alongside it.

## SKILL.md format

```yaml
---
name: my-skill
description: What this skill does and when to use it
disable-model-invocation: true   # only you can invoke it (good for /deploy, /commit)
user-invocable: false            # only Claude can invoke it (good for background knowledge)
allowed-tools: Read Grep         # tools Claude can use without asking
context: fork                    # run in isolated subagent
---

Your instructions here. Use $ARGUMENTS for user input.
```

All frontmatter fields are optional. `description` is strongly recommended — Claude uses it to decide when to auto-invoke.

## Invocation control

| Frontmatter                      | You can invoke | Claude can invoke |
|:---------------------------------|:---------------|:------------------|
| (default)                        | Yes            | Yes               |
| `disable-model-invocation: true` | Yes            | No                |
| `user-invocable: false`          | No             | Yes               |

## Arguments

Use `$ARGUMENTS` in skill content to receive user input:

```yaml
---
name: fix-issue
disable-model-invocation: true
---
Fix GitHub issue $ARGUMENTS following our coding standards.
```

Running `/fix-issue 123` replaces `$ARGUMENTS` with `123`.

Access individual arguments by position: `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, or shorthand `$0`, `$1`.

## Discovery

Skills are auto-discovered at session start — no registration needed. A session restart is required to pick up newly created skills. Use `/reload-plugins` to reload plugin skills without restarting.
