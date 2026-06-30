# yoyogipinball-md-stamp config — copy to ~/.config/mdstamp/config.sh
# (or set MDSTAMP_CONFIG to this file's path). Every value is optional;
# the defaults below are what stamp.sh uses when nothing is set.

# Mode: where the timestamp lives.
#   body        — a line in the document body (default)
#   frontmatter — a field inside the YAML --- block
export MDSTAMP_MODE=body

# date(1) format string. Keep the leading "+".
# %a is the weekday; under the C locale it yields Mon/Tue/... (locale-aware).
export MDSTAMP_DATE_FMT='+%Y-%m-%d'

# ----- body mode -----
# MARKER is a literal prefix used to find an existing line to replace.
# LINE is what gets written; {date} is substituted with the formatted date.
export MDSTAMP_BODY_MARKER='> Last updated:'
export MDSTAMP_BODY_LINE='> Last updated: {date}'

# ----- frontmatter mode -----
# YAML field updated (or inserted) inside the frontmatter block.
export MDSTAMP_FIELD='lastmod'

# ----- example: reproduce the author's Japanese style -----
# Because %a already prints Mon/Tue/... no custom weekday code is needed.
# export MDSTAMP_DATE_FMT='+%Y-%m-%d（%a）%H:%M'
# export MDSTAMP_BODY_MARKER='> 最終更新:'
# export MDSTAMP_BODY_LINE='> 最終更新: {date}'
