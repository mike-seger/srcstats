#!/bin/bash

# Source the configuration from srcstats.env
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/srcstats.env"

# Function to count lines in files matching a pattern
count_lines_matching_pattern() {
    local file="$1"
    grep -E "$LINE_PATTERN" "$file" | wc -l
}

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <max_depth> <root_dir1> [<root_dir2> ...]"
    exit 1
fi

MAX_DEPTH=$1
shift
ROOT_DIRS=("$@")

# Build the inclusion patterns
include_conditions=""
for pattern in "${START_PATTERNS[@]}"; do
    if [ -z "$include_conditions" ]; then
        include_conditions="-path \"$pattern*\""
    else
        include_conditions="$include_conditions -o -path \"$pattern*\""
    fi
done

# Build the exclusion patterns
exclude_conditions=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [ -z "$exclude_conditions" ]; then
        exclude_conditions="! -path \"$pattern*\""
    else
        exclude_conditions="$exclude_conditions -o ! -path \"$pattern*\""
    fi
done

# Construct the final find command
find_command="find ${ROOT_DIRS[@]} -type f \\( $include_conditions \\) \\( $exclude_conditions \\)"

# Temporary file to store intermediate results
temp_file=$(mktemp)

# Debug function
debug() {
    echo "$@" >&2
}

# Function to find the longest matching pattern
longest_matching_pattern() {
    local path="$1"
    local longest_match=""
    for pattern in "${START_PATTERNS[@]}"; do
        if [[ "$path" == *"$pattern"* ]] && [[ ${#pattern} -gt ${#longest_match} ]]; then
            longest_match="$pattern"
        fi
    done
    echo "$longest_match"
}

# Process directories
debug "finding files: $find_command"

eval $find_command | while read -r file; do
    lines_in_file=$(count_lines_matching_pattern "$file")
    longest_match=$(longest_matching_pattern "$file")
    echo -e "${file}\t${longest_match}\t${lines_in_file}" >> "$temp_file"
done

cat "$temp_file"

# Cleanup
rm "$temp_file"
