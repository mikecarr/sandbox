#!/bin/bash

# Define the paths to the temperature files
soc_temp_file="/sys/class/thermal/thermal_zone0/temp"
gpu_temp_file="/sys/class/thermal/thermal_zone1/temp"

# Check if files exist and are readable (optional but good practice)
if [[ ! -r "$soc_temp_file" ]]; then
    echo "Error: Cannot read $soc_temp_file" >&2
    exit 1
fi
if [[ ! -r "$gpu_temp_file" ]]; then
    echo "Error: Cannot read $gpu_temp_file" >&2
    exit 1
fi

# --- Calculate using awk ---
# awk reads the file directly. $1 refers to the first field (the whole line here).
# printf within awk formats the output.

soc_temp_c=$(awk '{printf "%.2f", $1 / 1000}' "$soc_temp_file")
gpu_temp_c=$(awk '{printf "%.2f", $1 / 1000}' "$gpu_temp_file")

soc_temp_f=$(awk '{printf "%.2f", ($1 / 1000 * 9 / 5) + 32}' "$soc_temp_file")
gpu_temp_f=$(awk '{printf "%.2f", ($1 / 1000 * 9 / 5) + 32}' "$gpu_temp_file")

# --- Output the results ---
echo "SOC Temp: $soc_temp_c C / $soc_temp_f F"
echo "GPU Temp: $gpu_temp_c C / $gpu_temp_f F"

# Alternative awk approach (reads each file only once)
# read soc_temp_c soc_temp_f < <(awk '{ c = $1 / 1000; f = (c * 9 / 5) + 32; printf "%.2f %.2f\n", c, f }' "$soc_temp_file")
# read gpu_temp_c gpu_temp_f < <(awk '{ c = $1 / 1000; f = (c * 9 / 5) + 32; printf "%.2f %.2f\n", c, f }' "$gpu_temp_file")
# echo "--- Alternative awk output ---"
# echo "SOC Temp: $soc_temp_c C / $soc_temp_f F"
# echo "GPU Temp: $gpu_temp_c C / $gpu_temp_f F"
