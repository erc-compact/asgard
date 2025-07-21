#!/bin/bash

# Check if the root directory is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <root_directory>"
  exit 1
fi

# Assign the root directory
ROOT_DIR="$1"

# Find all directories containing .dada files
find "$ROOT_DIR" -type f -name "*.dada" | while read -r dada_file; do
  # Get the directory of the dada file
  dada_dir=$(dirname "$dada_file")
  
  
  # Get the first dada file in sorted order
  first_dada_file=$(ls -v $dada_dir/*.dada 2>/dev/null | head -n 1)
  # Check if a dada file exists
  if [ -n "$first_dada_file" ]; then
    # Extract UTC_START value
    utc_start=$(head -c 4096 "$first_dada_file" | grep -a "UTC_START" | awk '{print $2}')
    
    echo "$utc_start"
    break
  fi
done

