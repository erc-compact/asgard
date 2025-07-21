#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <source_dir> <UTC_string> <destination_dir>"
  exit 1
fi

# Assign command line arguments to variables
source_dir=$1
utc_string=$2
destination_dir=$3

# Find all matching files and count them
files_to_link=$(find "$source_dir" -type f -name "${utc_string}*")
file_count=$(echo "$files_to_link" | wc -l)

# Echo the number of files found
echo "Number of files to symlink: $file_count"

# Iterate through each found file
while IFS= read -r file; do
  # Get the relative directory structure
  relative_path=$(dirname "${file#$source_dir/}")

  # Create the same directory structure in the destination directory
  mkdir -p "$destination_dir/$relative_path"

  # Create the symlink
  symlink_path="$destination_dir/$relative_path/$(basename "$file")"
  ln -s "$file" "$symlink_path"
done <<< "$files_to_link"

