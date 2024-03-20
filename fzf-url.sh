#!/usr/bin/env bash
#===============================================================================
#   Author: Wenxuan
#    Email: wenxuangm@gmail.com
#  Created: 2018-04-06 12:12
#===============================================================================
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

open_url() {
    if [[ -n $custom_open ]]; then
        $custom_open "$@"
    elif hash xdg-open &>/dev/null; then
        nohup xdg-open "$@"
    elif hash open &>/dev/null; then
        nohup open "$@"
    elif [[ -n $BROWSER ]]; then
        nohup "$BROWSER" "$@"
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

re_line="[0-9]\+:"
re_line_extended="[0-9]+:"
urls=$(echo "$content" | grep -noE '(https?|ftp|file):/?//[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]')
wwws=$(echo "$content" | grep -noE '(http?s://)?www\.[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}(/\S+)*' | grep -vE "^${re_line_extended}https?://" | sed "s/^\(${re_line}\)\(.*\)$/\1http:\/\/\2/")
ips=$(echo "$content" | grep -noE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?(/\S+)*' | sed "s/^\(${re_line}\)\(.*\)$/\1http:\/\/\2/")
gits=$(echo "$content" | grep -noE '(ssh://)?git@\S*' | sed "s/:/\//g" | sed "s/^\([0-9]\+\)\(\/\)/\1:/" | sed "s/^\(${re_line}\)\(ssh\/\/\/\)\{0,1\}git@\(.*\)$/\1https:\/\/\3/")
gh=$(echo "$content" | grep -noE "['\"]([_A-Za-z0-9-]*/[_.A-Za-z0-9-]*)['\"]" | sed "s/['\"]//g" | sed "s#^\(${re_line}\)\(.*\)#\1https://github.com/\2#")

if [[ $# -ge 1 && "$1" != '' ]]; then
    extras=$(eval "$1" <<<"$content" | ensure_line_number)
fi

items=$(
    printf '%s\n' "${urls[@]}" "${wwws[@]}" "${gh[@]}" "${ips[@]}" "${gits[@]}" "${extras[@]}" |
        grep -v '^$' |
        sort_items "$sort_cmd" |
        nl -w3 -s '  '
)
[ -z "$items" ] && tmux display 'tmux-fzf-url: no URLs found' && exit

re_index_1="\s*\([0-9]\+\)\s*"
re_line_2="\([0-9]\+\):"
re_match_3="\(.*\)"
re_item="^${re_index_1}${re_line_2}${re_match_3}$"
lines=$(sed "s/${re_item}/\2/" <<<"$items")
indexed_matches=$(sed "s/${re_item}/\1 \3/" <<<"$items")

fzf_filter "$lines" "$content" <<<"$indexed_matches" | awk '{print $2}' |
    while read -r chosen; do
        open_url "$chosen" &>"/tmp/tmux-$(id -u)-fzf-url.log"
    done
