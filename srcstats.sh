#!/bin/bash

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
            echo "Pattern matched: $pattern for path: $path" >&2
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

# Temporary file to store intermediate results
temp_file=$(mktemp)
consolidated_file=$(mktemp)

# Debug function
debug() {
    echo "$@" >&2
}

# Find all directories
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
                if matches_any_pattern "$file" "${EXCLUDE_PATTERNS[@]}"; then
                    debug "File excluded: $file"
                else
                    if [ -f "$file" ]; then
                        debug "Counting file: $file"
                        lines_in_file=$(count_lines_matching_pattern "$file")
                        debug "File: $file, Lines: $lines_in_file"
                        num_files=$((num_files + 1))
                        num_lines=$((num_lines + lines_in_file))
                    fi
                fi
            done

            debug "Directory: $dir, Num Files: $num_files, Num Lines: $num_lines"
            # Output the result
            echo -e "${dir}\t${num_files}\t${num_lines}" >> "$temp_file"
        else
            debug "Directory excluded: $dir"
        fi
    fi
done

# Consolidate results for matching directories
debug "Consolidating results..."
while read -r line; do
    dir=$(echo "$line" | awk '{print $1}')
    files=$(echo "$line" | awk '{print $2}')
    lines=$(echo "$line" | awk '{print $3}')
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        if [[ "$dir" =~ $pattern ]]; then
            # Extract the base directory based on the include pattern
            base_dir=$(echo "$dir" | awk -v pat="$pattern" '{
                match($0, pat);
                print substr($0, 1, RLENGTH)
            }')
            debug "Consolidating directory: $base_dir, Files: $files, Lines: $lines"
            echo -e "${base_dir}\t${files}\t${lines}" >> "$consolidated_file"
        fi
    done
done < "$temp_file"

# Aggregate results
debug "Aggregating final results..."
awk -F'\t' '
{
    dir = $1
    files[dir] += $2
    lines[dir] += $3
}
END {
    for (dir in files) {
        print dir "\t" files[dir] "\t" lines[dir]
    }
}
' "$consolidated_file" > final_report.tsv

# Display the final report
cat final_report.tsv

# Cleanup
rm "$temp_file" "$consolidated_file"
