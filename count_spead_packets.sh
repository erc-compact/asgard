#!/bin/bash

# Check if directory is passed as an argument
if [ -z "$1" ]; then
  echo "Please provide a directory."
  exit 1
fi

# Get the directory from the first argument
DIRECTORY=$1

# Initialize an associative array to store counts
declare -A pattern_counts

# Loop through each file in the directory
for file in "$DIRECTORY"/*; do
  if [[ $file =~ _test_([0-9]{2})_ ]]; then
    pattern=${BASH_REMATCH[1]}
    ((pattern_counts[$pattern]++))
  fi
done

# Print the counts for each pattern with headers and sorted
echo "Bridge Number | Count"
echo "--------------|------"
for pattern in $(printf "%s\n" "${!pattern_counts[@]}" | sort); do
  echo "     $pattern      | ${pattern_counts[$pattern]}"
done
