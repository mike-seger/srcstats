#!/bin/bash

if [ $# -lt 2 ] ; then
    echo "$0 <min consolidation path depth> <root path 1> ... [<root path n>]"
    exit 1
fi

# Source the configuration from srcstats.env
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/srcstats.env"

# Function to check if a path matches any pattern in a list
matches_any_pattern() {
    local path="$1"
    shift
    local patterns=("$@")
    for pattern in "${patterns[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

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

# Temporary file to store intermediate results
temp_file=$(mktemp)
consolidated_file=$(mktemp)

# Debug function
debug() {
    echo "$@" >&2
}

# Process each root directory
for ROOT_DIR in "${ROOT_DIRS[@]}"; do
    debug "Scanning directories in $ROOT_DIR..."
    find "$ROOT_DIR" -type d | while read -r dir; do
        # Check if the directory has no child directories
        if [ -z "$(find "$dir" -mindepth 1 -type d)" ]; then
            # Check if the directory should be included
            if matches_any_pattern "$dir" "${INCLUDE_PATTERNS[@]}"; then
                debug "Processing directory: $dir"
                # Count files and lines in the directory
                num_files=0
                num_lines=0
                files=$(find "$dir" -type f)
                for file in $files; do
                    debug "Considering file: $file"
                    include_file=false
                    if matches_any_pattern "$file" "${INCLUDE_PATTERNS[@]}"; then
                        include_file=true
                    elif ! matches_any_pattern "$file" "${EXCLUDE_PATTERNS[@]}"; then
                        include_file=true
                    fi
                    if $include_file; then
                        if [ -f "$file" ]; then
                            debug "Counting file: $file"
                            lines_in_file=$(count_lines_matching_pattern "$file")
                            debug "File: $file, Lines: $lines_in_file"
                            num_files=$((num_files + 1))
                            num_lines=$((num_lines + lines_in_file))
                        fi
                    else
                        debug "File excluded: $file"
                    fi
                done

                debug "Directory: $dir, Num Files: $num_files, Num Lines: $num_lines"
                # Output the result with the matched pattern category
                for pattern in "${INCLUDE_PATTERNS[@]}"; do
                    if [[ "$dir" =~ $pattern ]]; then
                        echo -e "${dir}\t${pattern}\t${num_files}\t${num_lines}" >> "$temp_file"
                        break
                    fi
                done
            else
                debug "Directory excluded: $dir"
            fi
        fi
    done
done

# Consolidate results for matching directories
debug "Consolidating results..."
while read -r line; do
    dir=$(echo "$line" | awk '{print $1}')
    pattern=$(echo "$line" | awk '{print $2}')
    files=$(echo "$line" | awk '{print $3}')
    lines=$(echo "$line" | awk '{print $4}')
    for include_pattern in "${INCLUDE_PATTERNS[@]}"; do
        if [[ "$dir" =~ $include_pattern ]]; then
            # Extract the base directory up to the matched include pattern
            base_dir=$(echo "$dir" | awk -v pat="$include_pattern" '{
                match($0, pat);
                print substr($0, 1, RLENGTH)
            }')
            debug "Consolidating directory: $base_dir, Pattern: $include_pattern, Files: $files, Lines: $lines"
            echo -e "${base_dir}\t${include_pattern}\t${files}\t${lines}" >> "$consolidated_file"
            break
        fi
    done
done < "$temp_file"

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
    dir = trim_path($1, max_depth) "/" $2
    files[dir] += $3
    lines[dir] += $4
}
END {
    for (dir in files) {
        print dir "\t" files[dir] "\t" lines[dir]
    }
}
' "$consolidated_file" | sed 's/\/\.\.\.\//\//g' | sort

# Cleanup
rm "$temp_file" "$consolidated_file"
