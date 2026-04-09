# Memory

> Official documentation: https://docs.anthropic.com/en/docs/claude-code/memory

Claude Code memory is how instructions, preferences, and learned knowledge persist across sessions. There are two distinct systems: **instruction memory** (CLAUDE.md files and rules) which you write, and **auto-memory** which Claude writes for itself.

---

## Instruction Memory (CLAUDE.md)

CLAUDE.md files inject instructions into Claude's context at session start. Multiple files from different scopes all concatenate — they don't override each other.

### File locations

| Scope | Location | Shared via git | Use for |
|:------|:---------|:---------------|:--------|
| Managed (highest) | `/etc/claude-code/CLAUDE.md` (Linux) | N/A — deployed by IT | Org-wide policies, always applied |
| Project | `./.claude/CLAUDE.md` or `./CLAUDE.md` | Yes | Team standards, build commands, architecture |
| Local | `./CLAUDE.local.md` | No — gitignore this | Personal sandbox URLs, local test data |
| User (lowest) | `~/.claude/CLAUDE.md` | N/A | Personal preferences across all projects |

**Load order:** Claude walks up the directory tree from `cwd`, collecting every CLAUDE.md and CLAUDE.local.md it finds. Subdirectory CLAUDE.md files are loaded on-demand when Claude reads files in that directory — not at startup.

**Managed CLAUDE.md cannot be excluded.** All other files can be excluded per-scope using `claudeMdExcludes` in settings.

### Importing other files

Reference files inside CLAUDE.md with `@path/to/file`:

```markdown
@README.md
@docs/architecture.md
See also: @package.json
```

- Paths are relative to the importing file
- Absolute paths work: `@~/.claude/shared-rules.md`
- Max import depth: 5 levels
- HTML comments are stripped before injection (saves tokens)

### Path-scoped rules (`.claude/rules/`)

For large projects, split instructions into modular files:

```
.claude/
├── CLAUDE.md
└── rules/
    ├── code-style.md        # loads always
    ├── testing.md           # loads always
    └── api/
        └── endpoints.md     # loads only for matching files
```

Rules with a `paths` frontmatter only load when Claude opens a matching file:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
---

All endpoints must validate input and return standard error shapes.
```

Rules without `paths` frontmatter load unconditionally at startup.

User-level rules live at `~/.claude/rules/` and apply to every project.

### Size and effectiveness

- Keep each CLAUDE.md under 200 lines — larger files reduce adherence
- Be specific: `"Run npm test before committing"` works better than `"Test your code"`
- Avoid contradictions across files — Claude merges all of them
- Use `.claude/rules/` and `@imports` to break large files into focused pieces

### Excluding files

In `.claude/settings.local.json` or `~/.claude/settings.json`:

```json
{
  "claudeMdExcludes": [
    "**/some-dir/CLAUDE.md",
    "/absolute/path/to/CLAUDE.md"
  ]
}
```

Patterns match against absolute paths using glob syntax. Arrays merge across settings scopes.

---

## Auto-Memory

Auto-memory is Claude-generated, project-scoped knowledge that persists across sessions. Claude writes to it when it discovers something useful — build commands, error patterns, architecture notes, workflow habits.

### Storage location

```
~/.claude/projects/<repo-slug>/memory/
├── MEMORY.md          # main index, loaded at session start
├── debugging.md       # topic files, loaded on-demand
├── api-conventions.md
└── ...
```

The repo slug derives from the git root, so all worktrees of the same repository share one memory directory.

Custom location (user or local settings only — not project settings):

```json
{
  "autoMemoryDirectory": "~/my-custom-memory"
}
```

### How it loads

- First 200 lines (or 25 KB) of `MEMORY.md` load automatically at session start
- Content beyond that threshold is accessible but not pre-loaded
- Topic files (`debugging.md`, etc.) are not auto-loaded — Claude reads them on-demand when needed

### Enable / disable

Auto-memory is on by default. Toggle with `/memory` inside a session, or set in settings:

```json
{
  "autoMemoryEnabled": false
}
```

Or via environment variable for a single session:

```bash
CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude
```

### Auto-dream (background consolidation)

When `autoDreamEnabled` is true, Claude periodically consolidates and reorganizes auto-memory in the background — merging redundant entries, pruning stale content, and improving structure. Set in settings:

```json
{
  "autoDreamEnabled": true
}
```

### Auditing and editing

Auto-memory files are plain markdown. Run `/memory` to browse the memory folder, then open any file in your editor to read, edit, or delete entries. Because these are plain files, you can also manage them directly from the shell.

---

## The `/memory` command

Running `/memory` inside a session shows:

- All CLAUDE.md files currently loaded (global, project, local)
- All `.claude/rules/` files with path-scope annotations
- A toggle to enable/disable auto-memory
- A shortcut to open the auto-memory folder

Use it to verify your instructions loaded, inspect what Claude has remembered, or disable auto-memory for the current session.

---

## Memory and context compaction

When `/compact` runs:

| Memory type | Survives compaction? |
|:------------|:---------------------|
| CLAUDE.md files | Yes — re-read from disk and re-injected |
| Auto-memory (MEMORY.md) | Yes — first 200 lines re-loaded |
| Conversation history | Summarized — not preserved verbatim |

If instructions disappear after compaction, they were given only in conversation. Move them to CLAUDE.md to make them survive.

### PreCompact and PostCompact hooks

These hooks fire around compaction. They are observability-only — they cannot block or modify the compaction itself.

```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{
        "type": "command",
        "command": "echo \"$(date) compaction starting\" >> ~/.claude/compact-log.txt"
      }]
    }],
    "PostCompact": [{
      "matcher": "manual",
      "hooks": [{
        "type": "command",
        "command": "echo \"$(date) compaction done\" >> ~/.claude/compact-log.txt"
      }]
    }]
  }
}
```

Hook stdin payload for both events:

```json
{
  "session_id": "abc123",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/home/user/project",
  "hook_event_name": "PreCompact",
  "compact_reason": "auto"
}
```

`compact_reason` is either `"auto"` (context limit triggered) or `"manual"` (`/compact` command).

---

## Memory type comparison

| | CLAUDE.md | Auto-memory | Conversation |
|:--|:----------|:------------|:-------------|
| Written by | You | Claude | Both |
| Persists across sessions | Yes | Yes | No |
| Survives `/compact` | Yes (full file) | Yes (first 200 lines) | Summarized |
| Syncs across machines | Via git (project files) | No — machine-local | No |
| Context cost | File size | Up to 25 KB | Grows per turn |
| Scope | Project / user / org | Per repository | Current session |

---

## Troubleshooting

**Claude isn't following my CLAUDE.md**
Run `/memory` to confirm the file is listed as loaded. Check for conflicting instructions across files. Make instructions specific and verifiable.

**Instructions disappeared after `/compact`**
They were only in conversation. Add them to CLAUDE.md.

**I don't know what auto-memory saved**
Run `/memory` → open the memory folder. Files are plain markdown — read, edit, or delete freely.

**CLAUDE.md is too large**
Split using `@imports` or move content to `.claude/rules/` files with path-scoped loading.
