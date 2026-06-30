# yoyogipinball-md-stamp

Auto-stamp a **"last updated"** marker into your Markdown files — **without breaking YAML frontmatter**. Works as a Claude Code `PostToolUse` hook (stamps live as you edit) and/or a git `pre-commit` hook (stamps on commit).

```
> Last updated: 2026-06-23
```

or, in frontmatter mode:

```yaml
---
title: My Post
lastmod: 2026-06-23
---
```

## Why not just a one-line git hook?

Almost every "update last-modified date" snippet **prepends** the timestamp to the top of the file. The moment your file starts with frontmatter:

```yaml
---
name: my-skill
description: ...
---
```

a naive hook pushes that block off line 1:

```
> Last updated: 2026-06-23
---            ← frontmatter no longer starts at line 1
name: my-skill
```

…and anything that requires frontmatter on line 1 silently breaks:

- **Claude Code skills/agents** stop loading — `name`/`description` can't be parsed, so the skill never triggers.
- **Jekyll / Hugo** stop treating the file as a page (front matter must be first).
- **Obsidian Properties** no longer recognizes the block.

`yoyogipinball-md-stamp` parses the frontmatter block and inserts **after** it (or updates a field **inside** it). It also only ever touches the **first** matching line, so a sample `> Last updated:` inside a code block in your docs is left alone.

> If you use a static site generator, note it can often derive `lastmod` from git commit time for free (e.g. Hugo's `enableGitInfo`). This tool is for when you want the date **visible in the raw file** — Obsidian vaults, Claude Code skill repos, plain Markdown docs.

## Features

- **Two modes** — a body line (`> Last updated: …`) or a frontmatter field (`lastmod: …`).
- **Frontmatter-safe** — never displaces the `--- … ---` block.
- **First-match-only** — won't clobber example lines elsewhere in the doc.
- **Symlink-aware** — resolves to the real file before writing (handy for dotfiles symlinked into a repo).
- **CRLF-tolerant** — detects frontmatter even with Windows line endings.
- **Portable** — pure `awk` + `date` + `git`; no GNU-sed-only tricks.
- **Configurable format** — any `date(1)` format and any label, via env vars or a config file.

## Install

```bash
git clone https://github.com/YoyogiPinball/yoyogipinball-md-stamp.git
chmod +x yoyogipinball-md-stamp/stamp.sh yoyogipinball-md-stamp/hooks/*
```

### As a Claude Code hook (live stamping)

Merge `settings.snippet.json` into `~/.claude/settings.json`, using the absolute path to `hooks/claude-posttooluse.sh`. Now every `.md` Claude writes/edits gets stamped immediately. Requires `jq`.

### As a git pre-commit hook (stamp on commit)

```bash
ln -s "$PWD/yoyogipinball-md-stamp/hooks/pre-commit" .git/hooks/pre-commit
```

`stamp.sh --staged` stamps every staged Markdown file and re-stages it, so the timestamp lands in the same commit.

### Manual

```bash
./stamp.sh path/to/file.md      # stamp one file
./stamp.sh --staged             # stamp all staged *.md
```

## Configuration

Set env vars, or copy `config.example.sh` to `~/.config/mdstamp/config.sh`.

| Variable | Default | Meaning |
|----------|---------|---------|
| `MDSTAMP_MODE` | `body` | `body` or `frontmatter` |
| `MDSTAMP_DATE_FMT` | `+%Y-%m-%d` | any `date(1)` format (keep the `+`) |
| `MDSTAMP_BODY_MARKER` | `> Last updated:` | literal prefix locating an existing body line |
| `MDSTAMP_BODY_LINE` | `> Last updated: {date}` | body line written; `{date}` is substituted |
| `MDSTAMP_FIELD` | `lastmod` | YAML field name in frontmatter mode |
| `MDSTAMP_CONFIG` | `~/.config/mdstamp/config.sh` | config file path |

`%a` prints the weekday (`Mon`, `Tue`, …) under the C locale, so a date like `2026-06-23（Tue）15:00` needs no custom code — just a format string.

## Requirements & limits

- `bash`, `awk`, `date`, `git` (and `jq` for the Claude Code wrapper). No GNU sed required; works on macOS and Linux.
- Inserted/rewritten lines are written with `\n`. On a CRLF file, newly added lines use LF (existing lines are preserved); normalize line endings if you need strict CRLF throughout.
- Frontmatter mode assumes a leading `--- … ---` block; if absent it creates one.

## License

MIT
