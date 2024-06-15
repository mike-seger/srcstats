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
        include_conditions="-path \"${pattern}*\""
    else
        include_conditions="$include_conditions -o -path \"${pattern}*\""
    fi
done

# Build the exclusion patterns
exclude_conditions=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [ -z "$exclude_conditions" ]; then
        exclude_conditions="! -path \"$pattern\""
    else
        exclude_conditions="$exclude_conditions -o ! -path \"$pattern\""
    fi
done

# Construct the final find command
find_command="find ${ROOT_DIRS[@]} -type f \\( $include_conditions \\) \\( $exclude_conditions \\)"

# Temporary file to store intermediate results
temp_file=$(mktemp)
consolidated_file=$(mktemp)

# Debug function
debug() {
    echo "$@" >&2
}

# Process directories
debug "finding files: $find_command"

eval $find_command | while read -r file; do
    lines_in_file=$(count_lines_matching_pattern "$file")
    echo -e "${file}\t${lines_in_file}" >> "$temp_file"
done

# Consolidate results for matching directories
debug "Consolidating results..."
awk -F'\t' '{files[$1] += 1; lines[$1] += $2} END {for (dir in files) print dir, files[dir], lines[dir]}' OFS='\t' "$temp_file" > "$consolidated_file"

cp "$consolidated_file" /tmp/1

# Aggregate results with specified depth and categories
debug "Aggregating final results with max depth $MAX_DEPTH..."
echo -e "path\tfiles\tlines"
awk -v max_depth="$MAX_DEPTH" -F'\t' '
function trim_path(path, depth) {
    split(path, parts, "/")
    if (length(parts) <= depth) {
        return path
    }
    result = parts[1]
    for (i = 2; i <= depth; i++) {
        result = result "/" parts[i]
    }
    return result "/..."
}
{
    dir = trim_path($1, max_depth)
    files[dir] += $2
    lines[dir] += $3
}
END {
    for (dir in files) {
        print dir "\t" files[dir] "\t" lines[dir]
    }
}
' "$consolidated_file" | sed 's/\/\.\.\.\//\//g' | sort

# Cleanup
rm "$temp_file" "$consolidated_file"
