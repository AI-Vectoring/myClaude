# Skills vs Commands vs Plugins

A guide to choosing the right extension mechanism in Claude Code.

## What each one is

| | Skills | Commands | Plugins |
|:--|:--|:--|:--|
| What it is | Directory with `SKILL.md` | Single `.md` file | Packaged bundle with `plugin.json` |
| Scope | Personal or project | Personal or project | Global, across all projects |
| Invocation | `/skill-name` | `/command-name` | `/plugin-name:skill-name` |
| Supporting files | Yes (templates, scripts) | No | Yes |
| Distributable | Via version control | Via version control | Via marketplace |
| Namespaced | No | No | Yes |

## Which to use when

**Use a standalone skill** (`~/.claude/skills/`) when:
- You want a personal `/slash-command` available in all your projects
- You may want supporting files alongside the instructions
- You want a short name like `/refresh` or `/deploy`

**Use a command** (`.claude/commands/`) when:
- You want a quick single-file slash command for one project
- You don't need supporting files
- You're okay with it being deprecated eventually

**Use a plugin** when:
- You want to share functionality across a team or publicly
- You need to bundle skills + agents + hooks + MCP together
- You're okay with namespaced invocation (`/plugin:skill`)
- You want versioned, installable releases

## The myClaude approach

myClaude uses the plugin mechanism (`myClaude` is an installed plugin) for its own skills and agents. User-facing `/refresh` lives as a standalone personal skill in `~/.claude/skills/refresh/` for a short, unnamespaced invocation.

Plugin `CLAUDE.md` and `AGENTS.md` files are symlinked into `myClaude/plugins/<plugin>/` so their content can be controlled — stripping irrelevant content that would otherwise pollute your context every session.

## Key gotcha: session restart

Standalone skills (`~/.claude/skills/`) require a session restart to be discovered. Plugin skills use `/reload-plugins` instead.
