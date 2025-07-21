#!/bin/bash

# User input: root directory
read -p "Enter the root directory: " root

# Find all unique UTCs
utc_list=($(find $root -type f -name "*.zst" | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}' | sort | uniq))
total_utc=${#utc_list[@]}

# Output total unique UTCs
echo "Total unique UTCs: $total_utc"

# Iterate over all UTCs
for utc in "${utc_list[@]}"; do
  echo "UTC: $utc"
  
  # Find all files for this UTC and extract bridge numbers
  bridges=($(find $root -type f -name "${utc}_*.zst" | awk -F'_' '{print $3}' | sort | uniq))
  total_bridges=${#bridges[@]}
  
  echo "Number of unique bridges: $total_bridges"

  # Count files per bridge and accumulate file sizes
  for bridge in "${bridges[@]}"; do
    files=($(find $root -type f -name "${utc}_*_${bridge}_*.zst"))
    file_count=${#files[@]}
    total_size_bytes=0

    # Calculate total size of all files for this bridge
    for file in "${files[@]}"; do
      file_size=$(stat -c%s "$file")  # Get file size in bytes
      total_size_bytes=$((total_size_bytes + file_size))
    done

    # Convert total size to TB
    total_size_gb=$(echo "scale=2; $total_size_bytes / (1024^4)" | bc)

    # Output number of files and total size for this bridge
    echo "Bridge $bridge: $file_count files, $total_size_gb TB"
  done
done

