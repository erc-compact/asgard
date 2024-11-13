#!/bin/bash

# Check if directory is passed as an argument
if [ -z "$1" ]; then
  echo "Please provide a directory."
  exit 1
fi

# Get the directory from the first argument
DIRECTORY=$1
SOURCE=$2

# Initialize an associative array to store counts
declare -A pattern_counts

# Loop through each file in the directory
for file in "$DIRECTORY"/**/**/*; do
  if [[ $file =~ _${SOURCE}_([0-9]{2})_ ]]; then
    pattern=${BASH_REMATCH[1]}
    ((pattern_counts[$pattern]++))
  fi
done

# Print the counts for each pattern with leading zeros (two-digit format)
echo "Bridge Number | Count"
echo "--------------|------"
for pattern in $(printf "%s\n" "${!pattern_counts[@]}" | sort -n); do
  printf "     %02d      | %d\n" "$((10#$pattern))" "${pattern_counts[$pattern]}"
done

# Collect all patterns with counts greater than 100 in a comma-separated string
result=""
for pattern in $(printf "%s\n" "${!pattern_counts[@]}" | sort -n); do
  if (( pattern_counts[$pattern] > 100 )); then
    result+="$((10#$pattern)),"
  fi
done

# Echo the result as integers (no leading zeros)
if [[ -n $result ]]; then
  echo "${result%,}"
fi

