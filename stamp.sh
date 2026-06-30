#!/usr/bin/env bash
# stamp.sh — frontmatter-safe "last updated" stamper for Markdown
#
# Writes/updates a "last updated" marker in a Markdown file WITHOUT breaking
# YAML frontmatter. The marker can live either as a body line (e.g. a blockquote)
# or as a field inside the frontmatter block.
#
# Usage:
#   stamp.sh <file.md>     # stamp a single file
#   stamp.sh --staged      # stamp every staged *.md, then re-stage them (git hook)
#
# Configuration (env vars; an optional config file is sourced first):
#   MDSTAMP_CONFIG       path to a config file (default: ~/.config/mdstamp/config.sh)
#   MDSTAMP_MODE         body | frontmatter            (default: body)
#   MDSTAMP_DATE_FMT     date(1) format, keep "+"      (default: +%Y-%m-%d)
#   MDSTAMP_BODY_MARKER  literal prefix that locates an existing line
#                                                      (default: "> Last updated:")
#   MDSTAMP_BODY_LINE    line to write; {date} is substituted
#                                                      (default: "> Last updated: {date}")
#   MDSTAMP_FIELD        YAML field name in frontmatter mode (default: lastmod)
#
# Why this exists: naive timestamp hooks prepend a line to the top of the file.
# When the file starts with YAML frontmatter (--- ... ---), that pushes the
# frontmatter off line 1 and silently breaks tools that require it there
# (Claude Code skills/agents, Jekyll/Hugo, Obsidian Properties). This script
# inserts AFTER the frontmatter block, and only ever touches the first match.

set -euo pipefail

CONFIG_FILE="${MDSTAMP_CONFIG:-$HOME/.config/mdstamp/config.sh}"
# shellcheck disable=SC1090
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

MODE="${MDSTAMP_MODE:-body}"
DATE_FMT="${MDSTAMP_DATE_FMT:-+%Y-%m-%d}"
BODY_MARKER="${MDSTAMP_BODY_MARKER:-> Last updated:}"
BODY_LINE="${MDSTAMP_BODY_LINE:-> Last updated: {date}}"
FIELD="${MDSTAMP_FIELD:-lastmod}"

# Resolve symlinks to the real path. A bare `sed -i`/`mv` on a symlink can
# replace the link itself instead of its target; we always operate on the
# resolved file. `readlink -f` is GNU-only, so fall back to realpath, then noop.
resolve_path() {
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    elif readlink -f "$1" >/dev/null 2>&1; then
        readlink -f "$1"
    else
        printf '%s\n' "$1"
    fi
}

now="$(date "$DATE_FMT")"

update_file() {
    local file="$1"
    case "$file" in
        *.md | *.markdown) ;;
        *) return 0 ;;
    esac
    [ -f "$file" ] || return 0

    local real tmp
    real="$(resolve_path "$file")"
    tmp="$(mktemp)"

    if [ "$MODE" = "frontmatter" ]; then
        local fieldline="${FIELD}: ${now}"
        # Update the field inside the frontmatter block, or create the block.
        awk -v fieldline="$fieldline" -v fkey="${FIELD}:" '
            { raw[NR]=$0; c=$0; sub(/\r$/,"",c); clean[NR]=c }
            END {
                n=NR
                fmopen=(n>=1 && clean[1]=="---")
                fmclose=0
                if (fmopen) { for(i=2;i<=n;i++) if(clean[i]=="---"){fmclose=i;break} }
                if (fmopen && fmclose>0) {
                    found=0
                    for(i=2;i<fmclose;i++) if(index(clean[i],fkey)==1){found=i;break}
                    if (found) { for(i=1;i<=n;i++) print (i==found)?fieldline:raw[i] }
                    else       { for(i=1;i<=n;i++){ if(i==fmclose) print fieldline; print raw[i] } }
                } else {
                    print "---"; print fieldline; print "---"
                    if (n>0){ print ""; for(i=1;i<=n;i++) print raw[i] }
                }
            }
        ' "$real" > "$tmp"
    else
        local newline="${BODY_LINE/\{date\}/$now}"
        # Replace the first line starting with the marker, else insert it after
        # the frontmatter block (or at the top when there is no frontmatter).
        awk -v newline="$newline" -v marker="$BODY_MARKER" '
            { raw[NR]=$0; c=$0; sub(/\r$/,"",c); clean[NR]=c }
            END {
                n=NR
                fmopen=(n>=1 && clean[1]=="---")
                fmclose=0
                if (fmopen) { for(i=2;i<=n;i++) if(clean[i]=="---"){fmclose=i;break} }
                found=0
                for(i=1;i<=n;i++) if(index(clean[i],marker)==1){found=i;break}
                if (found) {
                    for(i=1;i<=n;i++) print (i==found)?newline:raw[i]
                } else if (fmopen && fmclose>0) {
                    for(i=1;i<=n;i++){ print raw[i]; if(i==fmclose){ print ""; print newline } }
                } else {
                    print newline; print ""
                    for(i=1;i<=n;i++) print raw[i]
                }
            }
        ' "$real" > "$tmp"
    fi

    # Preserve the original inode/permissions (matters for symlink targets and
    # cross-filesystem temp dirs) by writing back through the existing file.
    cat "$tmp" > "$real"
    rm -f "$tmp"
}

if [ "${1:-}" = "--staged" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        update_file "$file"
        git add "$file"
    done < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|markdown)$' || true)
else
    [ -z "${1:-}" ] && { echo "Usage: $0 <file.md> | --staged" >&2; exit 1; }
    update_file "$1"
fi
