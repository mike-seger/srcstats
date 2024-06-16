#!/usr/bin/env bash

debug=false

export tsdate=date
if [ -x "$(which gdate)" ] ; then
	export tsdate=gdate
fi

function usage() {
    echo "Usage: $0 [-ef <env-file> | -e <env-file-type>] <max_depth> <root_dir1> [<root_dir2> ...]"
    exit 1
}

ts=$($tsdate +%s%N)
function debug() {
    if [ "$debug" == "true" ] ; then
	ts1=$($tsdate +%s%3N)
	diff=$((ts1 - ts))
	ts=$ts1
        echo "$diff: $@" >&2
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

# Check arguments
if [ "$#" -lt 2 ]; then
    usage
fi

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

# Pre-compile patterns
declare -A COMPILED_PATTERNS
for pattern in "${FILE_PATTERNS[@]}"; do
    COMPILED_PATTERNS["$pattern"]="$(conv_pattern "$pattern")"
done

function longest_matching_pattern1() {
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

function longest_matching_pattern() {
    local path="$1"
    local longest_match=""
    local longest_length=0

    for pattern in "${!COMPILED_PATTERNS[@]}"; do
        local pat="${COMPILED_PATTERNS[$pattern]}"
        if [[ "$path" == $pat ]] && [[ ${#pattern} -gt $longest_length ]]; then
            longest_match="$pattern"
            longest_length=${#pattern}
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
find ${ROOT_DIRS[@]} -type f | while read -r file; do
    debug "Stats: $file"
    longest_match=$(longest_matching_pattern "$file")
    if [ -z "$longest_match" ] ; then
        debug "Non matching file pattern: $file"
    else
        if [ $(is_binary "$file") ] ; then
            debug "Skipping binary file: $file"
            continue
        fi    
    fi
#    debug "X002 match"
    lines_in_file=$(count_lines_matching_pattern "$file")
    if [ "$lines_in_file" -lt "$MIN_FILE_LINES" ] ; then
        debug "File has less than $MIN_FILE_LINES lines: $file"
        continue
    fi
#    debug "X003 count"
    file2=$(truncate_at_match $file $longest_match)    
#    debug "X004 trunc"
    trimmed_path=$(trim_path "$file2" "$MAX_DEPTH")
#    debug "X005 trim"
    lmpat=$(echo "$longest_match" | tr -d '$*'|sed -e "s#^\.*##")
#    debug "X006 lmpat"
    echo -e "${trimmed_path}...${lmpat}\t${lines_in_file}"
#    debug "X007 echo"
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
