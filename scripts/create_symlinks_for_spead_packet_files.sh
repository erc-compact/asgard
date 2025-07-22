#!/bin/bash

src_root="/media/inner"
target_root="/b/p/DATA/BASEBAND/SPEAD/M70/inner"


mkdir -p "$target_root"

for subdir in "$src_root"/*; do
    [[ -d "$subdir" ]] || continue
    subname=$(basename "$subdir")
    target_subdir="$target_root/$subname"
    mkdir -p "$target_subdir"

    find "$subdir" -maxdepth 1 -type f -name "*.zst" | while read -r zstfile; do
        filesize=$(stat -c%s "$zstfile")
        if (( filesize >= 100 )); then
            ln -sfn "$zstfile" "$target_subdir/$(basename "$zstfile")"
        fi
    done
done

