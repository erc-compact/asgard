#!/usr/bin/env bash
for i in /b/DATA/BASEBAND/SPEAD/NGC1851_SYMLINKS/NGC1851/fbfcn21/top/*.zst; do
#for i in /b/DATA/BASEBAND/SPEAD/NGC1851/fbfcn29/top/2024-05-19T15:50:07Z_NGC1851_58*.zst; do
    /workspace/BEAMFORMER/meerkat-data-distribution/distribute -c bridge_43.conf -r "$i" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error occurred for file: $i (exit code: $?)"
    fi
done

