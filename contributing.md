# Contributing

## Before you start

- Open an issue first for anything beyond a trivial fix
- Check existing issues and PRs to avoid duplicates
- One problem per PR

## Process

1. Fork the repo
2. Create a branch named after the issue or feature
3. Make your changes — see [implementing.md](implementing.md) for internals
4. Test manually: `myClaude scan`, `myClaude repair`, `myClaude newRepo`
5. Submit a PR with a clear description of the problem solved

## Standards

- Shell scripts must pass `shellcheck`
- No new dependencies without discussion — `jq` and `gh` are the only runtime deps
- Commands must implement `--help`
- Keep `myClaude.conf` as the single source of configuration truth
