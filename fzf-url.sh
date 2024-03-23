#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONTENT_FILE="/tmp/tmux-fzf-url-content"

custom_open=$3
sort_cmd=$4
preview_enabled=$5

get_fzf_options() {
    local fzf_options
    local fzf_default_options='-w 100% -h 50% --multi -0'
    fzf_options="$(tmux show -gqv '@fzf-url-fzf-options')"
    [ -n "$fzf_options" ] && echo "$fzf_options" || echo "$fzf_default_options"
}

################################################################################
# Use fzf to filter stdin. Te first argument should be the line numbers stdin
# was found. The second argument should be the content that was used to create
# stdin and the lines numbers. When the global variable preview_enabled is set
# to true, a preview window will be enabled. The results can be filtered with
# the post_filter variable, after an item is selected.
#
# The content is written to a temporary file, as it makes displaying it in the
# preview window more stable when dealing with escape characters.
################################################################################
fzf_filter() {
    local lines content preview_cmd cmd
    lines="$1"
    content="$2"
    if $preview_enabled; then
        echo "$content" >"$CONTENT_FILE"
        preview_cmd="$SCRIPT_DIR/preview.sh \"$lines\" {n} \"$CONTENT_FILE\""
        eval "fzf-tmux --preview '$preview_cmd' $(get_fzf_options)"
    else
        eval "fzf-tmux $(get_fzf_options)"
    fi
}

################################################################################
# From stdin, the items are in the following format: line_number:item. First,
# duplicates are removed, i.e, matches that have the same item, and line number.
#
# Next, the argument that is passed to this function is used is applied to a
# second sort command. This is to allow the user to sort the items based on
# their preference. If the argument is empty, no extra sorting is done.
################################################################################
sort_items() {
    local cmd=${1:-cat}
    eval "sort -u | $cmd"
}

################################################################################
# Read content from stdin. If a line does not start with [0-9]+:, prepend 1: to
# it. This is to ensures that all lines have a line number, ensuring that fzf
# does not break when the user did not include line numbers in its exra filter.
################################################################################
ensure_line_number() {
    while IFS= read -r line; do
        if [[ -z $line ]]; then
            continue
        elif [[ ! $line =~ ^[0-9]+: ]]; then
            echo "1:$line"
        else
            echo "$line"
        fi
    done
}

limit='screen'
[[ $# -ge 2 ]] && limit=$2

if [[ $limit == 'screen' ]]; then
    content="$(tmux capture-pane -J -p -e)"
else
    content="$(tmux capture-pane -J -p -e -S -"$limit")"
fi

if [[ $# -ge 1 && "$1" != '' ]]; then
    extras=$(eval "$1" <<<"$content" | ensure_line_number)
fi

items=$(
    printf '%s\n' "${extras[@]}" | grep -v '^$' | sort_items "$sort_cmd"
)
[ -z "$items" ] && tmux display 'tmux-fzf-url: no URLs found' && exit

re_line="\([0-9]\+\):"
re_match="\(.*\)"
re_item="^${re_line}${re_match}$"
lines=$(sed "s/${re_item}/\1/" <<<"$items")
indexed_matches=$(sed "s/${re_item}/\2/" <<<"$items")

fzf_filter "$lines" "$content" <<<"$indexed_matches" | 
    while read -r chosen; do
        eval "$custom_open '$chosen'"
    done || true
