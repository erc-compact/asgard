#!/bin/bash

# Root directory path
#ROOT_DIR="/b/u/vishnu/00_DADA_FILES/J1644-4559/2024-02-16-11:16:08/L"
ROOT_DIR=$1

# Loop over each subdirectory in the root directory
for subdir in "$ROOT_DIR"/*; do
    if [ -d "$subdir" ]; then
        # Count the number of .dada files in the subdirectory
        count=$(find "$subdir" -maxdepth 1 -type f -name "*.dada" | wc -l)
        
        # Extract just the subdirectory name
        subdir_name=$(basename "$subdir")
        
        # Print the subdirectory name and the count of .dada files
        echo "Subdirectory: $subdir_name, .dada files: $count"
    fi
done

