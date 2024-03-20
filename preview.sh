#!/usr/bin/env bash
set -euo pipefail
#===============================================================================
#   Author: BartSte
#  Contact: github.com/BartSte
#  Created: 2024-03-20
#===============================================================================
usage="Usage: $(basename "$0") [options] <numbers> <index> <file>

Uses bat to display the text recieved stdin, while highlighting the line number
that corresponds to the <index>th element of <numbers>. Here, <numbers> is a
string of line numbers, separated by a newline, and <index> is a number. If the 
<file> is provided, it is used as the input instead of stdin.

For example: 

- stdin:
    1: This is the first line
    2: This is the second line
    3: This is the third line
    4: and so on ...
    5: and on ...

- <numbers>: 2\n3\n5
- <index>: 2

Now the line number 3 will be highlighted in the output using bat:

    1: This is the first line
    2: This is the second line
    --> 3: This is the third line <-- highlighted
    4: and so on ...
    5: and on ...

This script is typically used in combination with fzf's preview-window as
follows:

fzf --preview 'echo \$text | \$this_script \$numbers {n}'

where, \$text is the text to display, \$numbers is the list of line numbers,
and {n} is the index of the selected fzf entry. 

A typical use case is to display a text. On this text we apply a regex which
results in a list of matches in the format \`line_number:match\`. Next we feed
the matches to fzf, while the text, line numbers and the index go to this script.
As a result, the selected match is highlighted in the preview window.

stdin:
The text to display.

options:
-h --help   shows this help messages
-l --log    log debug information to this file

positional:
<numbers>   the list of line numbers separated by a newline
<index>     the index of the <numbers> to highlight"

bat_warning="
##############################################################################
Warning: bat/batcat is not installed. Using cat instead. By installing
bat/batcat, you can get syntax highlighting, automatic scrolling and the
selected option will be highlighted. To disable this warning, set the
environment variable FZF_HELP_BAT_WARNING to false.
##############################################################################
"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            echo "$usage"
            exit 0
            ;;
        -l | --log)
            logfile=$2
            shift
            ;;
        *)
            if [[ -z $numbers ]]; then
                numbers=$1
            elif [[ -z $index ]]; then
                index=$1
            elif [[ -z $file ]]; then
                file=$1
            else
                echo "Unknown argument: $1"
                echo "$usage"
                exit 1
            fi
            ;;
        esac
        shift
    done
}

################################################################################
# Returns half the number of lines of the terminal. If the environment variable
# FZF_PREVIEW_LINES is set, its value is returned instead.
################################################################################
get_half_page() {
    local number_of_lines
    number_of_lines=${FZF_PREVIEW_LINES:-}
    [[ -z $number_of_lines ]] && number_of_lines=$(tput lines)
    echo $(($number_of_lines / 2))
}

################################################################################
# Returns the number of lines to scroll up such that the line that need to be
# highlighted is in the middle of the screen.
################################################################################
get_scroll_lines() {
    local half_page line_number scroll
    line_number=$1
    half_page=$(get_half_page)
    scroll=$(($line_number - $half_page))
    scroll=$(($scroll > 0 ? $scroll : 0))
    echo $scroll
}

################################################################################
# Prints the bat warning message to stderr, if the environment variable
# FZF_HELP_BAT_WARNING is set to true.
################################################################################
print_bat_warning() {
    if [[ $show_bat_warning == "true" ]]; then
        echo "$bat_warning" >&2
    fi
}

################################################################################
# Logs the arguments to the file specified by the variable $output.
################################################################################
log() {
    echo "$@" >>"$logfile"
}

log_reset() {
    echo -n "" >"$logfile"
}

################################################################################
# Prints the debug information to log.
################################################################################
log_debug_info() {
    log "numbers: $numbers"
    log "index: $index"
    log "line_number: $number"
    log "scroll: $scroll"
    log "show_bat_warning: $show_bat_warning"
}

abort() {
    echo "$@" >&2
    exit 1
}

################################################################################
# Executes the args with batcat or bat, if one of them is installed. If none of
# them is installed, cat is used instead. If the environment variable
# FZF_HELP_BAT_WARNING is set to false, the warning message is not printed
# to stderr.
################################################################################
exec_bat() {
    log_debug_info
    if which batcat &>/dev/null; then
        batcat "$@"
    elif which bat &>/dev/null; then
        bat "$@"
    else
        print_bat_warning
        cat
    fi
}

numbers=""
index=""
logfile="/dev/null"
file=""
parse_args "$@"
log_reset
show_bat_warning="${FZF_URL_BAT_WARNING:-true}"

[[ -z $numbers ]] && echo "Missing <numbers>" && echo "$usage" && exit 1
[[ -z $index ]] && echo "Missing <index>" && echo "$usage" && exit 1

number=$(sed -n "$((index + 1))p" <<<"$numbers")
scroll=$(get_scroll_lines "$number")

[[ -z $index ]] && abort "Invalid index: $index"
[[ -z $number ]] && abort "Invalid number: $number"
[[ -z $scroll ]] && abort "Invalid scroll: $scroll"

printf '\033[2J'
exec_bat -f -pp -H "$number" -r "$scroll": "$file"
