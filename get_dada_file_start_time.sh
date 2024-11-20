#!/bin/bash

# User input: source name
read -p "Enter the source name: " source_name

# Root directory given by the user
root="/b/DATA/BASEBAND/SPEAD/$source_name/"

# Get unique UTCs for the specified source
utc_list=($(find "$root" -type f -name "*${source_name}_*" | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}' | sort | uniq))

# Check for multiple UTCs and print the number
total_utc=${#utc_list[@]}
echo "Total unique UTCs: $total_utc"

# Initialize file to store results
result_file="results_$source_name.txt"
echo "UTC Bridge RX_Buffer Time_Min" > "$result_file"

# Iterate over all UTCs
for utc in "${utc_list[@]}"; do
  echo "Processing UTC: $utc"
  min_time_for_utc=99999999999999  # Initialize high value for the UTC

  # Iterate over all bridges (00 to 63)
  for bridge in $(seq -w 0 63); do
    min_time_for_bridge=99999999999999  # Initialize high value for the bridge

    # Find the first file for this UTC, source name, and bridge
    first_file=$(find "$root" -type f -name "${utc}_${source_name}_${bridge}_*.zst" | sort | head -n 1)

    # Get the directory name from the first file
    if [ -z "$first_file" ]; then
      continue
    fi
    bridge_dir=$(dirname "$first_file")
    # Iterate over all RX buffer IDs (00 to 11)
    for rx_buffer in $(seq -w 0 11); do
      # Get the first available counter file in ascending order
      filename=$(find "$bridge_dir" -type f -name "${utc}_${source_name}_${bridge}_${rx_buffer}_*.zst" | sort | head -n 1)

      # Check if the file exists
      if [ -z "$filename" ]; then
        continue
      fi

      # Run the Apptainer command and extract "time min"
      sing_cmd="apptainer exec -H $HOME:/home1 -B /b:/b -B /bscratch:/bscratch -B /b/u/vishnu/BEAMFORMER/:/workspace/BEAMFORMER /b/u/vishnu/SINGULARITY_IMAGES/meerkat-data-distribution_dev3.sif"
      output=$($sing_cmd /workspace/BEAMFORMER/meerkat-data-distribution/distribute -c bridge_43.conf -r "$filename")
      time_min=$(echo "$output" | grep "time min" | awk '{print $3}')

      # Update the minimum time for this bridge and for the UTC
      if [ "$time_min" -lt "$min_time_for_bridge" ]; then
        min_time_for_bridge=$time_min
      fi
      if [ "$time_min" -lt "$min_time_for_utc" ]; then
        min_time_for_utc=$time_min
      fi

      # Save the result
      echo "$utc $bridge $rx_buffer $time_min" >> "$result_file"
    done

    # Print the minimum time across all RX buffers for this bridge
    echo "Minimum time for bridge $bridge: $min_time_for_bridge"
  done

  # Print the start time for the UTC
  echo "Start time for UTC $utc: $min_time_for_utc"
done

echo "Results saved to $result_file"

