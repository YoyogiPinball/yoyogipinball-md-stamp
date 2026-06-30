#!/usr/bin/env bash
# claude-posttooluse.sh — Claude Code PostToolUse hook wrapper.
#
# Wire it to the Write|Edit matcher (see settings.snippet.json). When Claude
# edits a Markdown file, this stamps it live — no commit needed.
#
# Reads the PostToolUse JSON payload on stdin and pulls out the edited path.
# Requires `jq`. Never blocks: any failure exits 0 so edits are not interrupted.

set -euo pipefail

INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

[ -z "$FILE" ] && exit 0
case "$FILE" in
    *.md | *.markdown) ;;
    *) exit 0 ;;
esac

DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP="${MDSTAMP_BIN:-$DIR/../stamp.sh}"
[ -x "$STAMP" ] || exit 0

"$STAMP" "$FILE" || exit 0
