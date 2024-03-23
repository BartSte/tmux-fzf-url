#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

tmux_opt() {
    local setting default value
    setting="$1"
    default="$2"
    value="$(tmux show -gqv "$setting")"
    [ -n "$value" ] && echo "$value" || echo "$default"
}

fzf_open_opt() {
    local setting default value name
    setting="$1"
    default="$2"
    value="$(tmux_opt "$setting" "$default")"
    if [[ -n "$value" ]]; then
        name="$(sed 's/@fzf-open-//g' <<<"$setting")"
        if [[ $value == true ]]; then
            echo "--$name"
        else
            echo "--$name '$value'"
        fi
    fi
}

key="$(tmux_opt '@fzf-open-bind' 'u')"
regex="$(fzf_open_opt '@fzf-open-regex' '')"
regex_extra="$(fzf_open_opt '@fzf-open-regex-extra' '')"
limit="$(fzf_open_opt '@fzf-open-limit' '')"
open_cmd="$(fzf_open_opt '@fzf-open-open-cmd' '')"
sort_cmd="$(fzf_open_opt '@fzf-open-sort-cmd' '')"
preview="$(fzf_open_opt '@fzf-open-preview' '')"

tmux bind-key "$key" run -b "$script_dir/fzf-open $regex $regex_extra $limit $open_cmd $sort_cmd $preview"
