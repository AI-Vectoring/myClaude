# Todo

## Scanner command

- Bash script scans `~/git/`, builds a state file with all repos and their status
- Flags per repo, including `do-not-include`
- `/scan-claude` command runs the script, reads output, reasons about what needs attention

## New repo command

- Entry point: repo creation
- `gh repo create`
- Clone to `~/git/`
- Create `my-claude/<reponame>/CLAUDE.md`
- Symlink `~/git/<reponame>/CLAUDE.md` → `my-claude/<reponame>/CLAUDE.md`
- LLM drafts initial `CLAUDE.md` content based on what the repo is for
