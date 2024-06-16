#!/bin/bash

debug=false

function usage() {
    echo "Usage: $0 [-ef <env-file> | -e <env-file-type>] <max_depth> <root_dir1> [<root_dir2> ...]"
    echo "  for example:"
    echo "  "
    exit 1
}

function debug() {
    if [ "$debug" == "true" ] ; then
        echo "$@" >&2
    fi
}

# source the configration based on options
SCRIPT_DIR=$(dirname "$0")
env_file="$SCRIPT_DIR/srcstats.env"

for arg in "$@"; do
    if [[ "$1" != "-"* ]] ; then break; fi
    
    if [ "$1" == '-ef' ] ; then
            shift
            env_file="$1"
            shift
    elif [ "$1" == '-e' ] ; then
            shift
            env_file="$SCRIPT_DIR/srcstats-${1}.env"
            shift
    elif [ "$1" == '-d' ] ; then
            shift
            debug=true
    else
    	usage
    fi
done

MAX_DEPTH=$1
shift
ROOT_DIRS=("$@")

debug "Env file: $env_file"
source "$env_file"

# Function to count lines in files matching a pattern
function count_lines_matching_pattern() {
    local file="$1"
    grep -E "$LINE_PATTERN" "$file" | wc -l
}

function conv_pattern() {
    local pattern="*$1*"
    if [[ "$1" == *'$' ]] ; then
    	pattern="*${1:0:$((${#1} - 1))}"
    fi
    echo "$pattern"
}

function is_binary() {
    head -c 1024 "$1" | grep -q "\x00" 
}

function path_conditions() {
    local include_conditions=""
    local predicate=$1
    shift
    local patterns=("$@")
    for pattern in "${patterns[@]}"; do
        pat=$(conv_pattern "$pattern")
        if [ -z "$include_conditions" ]; then
            include_conditions="$predicate -path \"$pat\""
        else
            include_conditions="$include_conditions -o $predicate -path \"$pat\""
        fi
    done
    echo $include_conditions
}

# Check arguments
if [ "$#" -lt 1 ]; then
        echo 002
	usage
fi

# Build the inclusion patterns
#include_conditions=$(path_conditions " " "${FILE_PATTERNS[@]}")

# Build the exclusion patterns
#exclude_conditions=$(path_conditions '!' "${EXCLUDE_PATTERNS[@]}")

# Construct the final find command
#find_command="find ${ROOT_DIRS[@]} -type f \\( $include_conditions \\) \\( $exclude_conditions \\)"

function longest_matching_pattern() {
    local path="$1"
    local longest_match=""
    for pattern in "${FILE_PATTERNS[@]}"; do
        pat=$(conv_pattern "$pattern")
        if [[ "$path" == $pat ]] && [[ ${#pattern} -gt ${#longest_match} ]]; then
            longest_match="$pattern"
        fi
    done
    echo "$longest_match"
}

function trim_path() {
    local path="$1"
    local depth="$2"
    path="${path#./}"  # Strip leading ./
    IFS='/' read -ra parts <<< "$path"
    if (( ${#parts[@]} <= depth )); then
        echo "$path"
    else
        result="${parts[0]}"
        for ((i = 1; i < depth; i++)); do
            result="$result/${parts[i]}"
        done
        echo "$result"
    fi
}

truncate_at_match() {
    local s1="$1"
    local s2="$2"
    local truncated

    # Check if s1 contains s2
    if [[ "$s1" == *"$s2"* ]]; then
        # Remove everything after the match
        truncated="${s1%%"$s2"*}"
    else
        truncated="$s1"
    fi

    echo "$truncated"
}

echo "Checking n files: $(find ${ROOT_DIRS[@]} -type f|wc -l)"
#eval $find_command | while read -r file; do
find ${ROOT_DIRS[@]} -type f | while read -r file; do
    debug "$file"
    if [ $(is_binary "$file") ] ; then
        debug "Skipping binary file: $file"
        continue
    fi
    lines_in_file=$(count_lines_matching_pattern "$file")
    if [ "$lines_in_file" -lt "$MIN_FILE_LINES" ] ; then
        debug "File has less than $MIN_FILE_LINES lines: $file"
        continue
    fi
    longest_match=$(longest_matching_pattern "$file")
    if [ -z "$longest_match" ] ; then
        debug "Non matching file pattern: $file"
    fi
    file2=$(truncate_at_match $file $longest_match)    
    trimmed_path=$(trim_path "$file2" "$MAX_DEPTH")
    lmpat=$(echo "$longest_match" | tr -d '$*'|sed -e "s#^\.*##")
    echo -e "${trimmed_path}...${lmpat}\t${lines_in_file}"
done |\
awk -F'\t' '
{
    key = $1
    sum[key] += $2
    count[key] += 1
}
END {
    for (key in sum) {
        print key "\t" count[key] "\t" sum[key]
    }
}
' | sort
