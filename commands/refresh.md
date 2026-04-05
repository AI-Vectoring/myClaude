Based on $ARGUMENTS, read and restate the rules from the following CLAUDE.md files, confirming you will follow them for the rest of this session:

- no argument or "global": read ~/.claude/CLAUDE.md only
- "all": read ~/.claude/CLAUDE.md, the CLAUDE.md at the project root, and the CLAUDE.md in the current working directory
- "project": read the CLAUDE.md at the project root only
- "dir": read the CLAUDE.md in the current working directory only

For each file read, list the rules found. If a file does not exist, say so and skip it.
