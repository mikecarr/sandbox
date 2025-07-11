#!/bin/sh
# Create comprehensive system info
INFO_FILE="/tmp/www/system_complete_info.txt"

echo "=== SYSTEM INFORMATION DUMP ===" > $INFO_FILE
echo "Generated: $(date)" >> $INFO_FILE

echo -e "\n=== CPU INFO ===" >> $INFO_FILE
cat /proc/cpuinfo >> $INFO_FILE 2>/dev/null

echo -e "\n=== MEMORY INFO ===" >> $INFO_FILE
cat /proc/meminfo >> $INFO_FILE 2>/dev/null

echo -e "\n=== NETWORK DEVICES ===" >> $INFO_FILE
cat /proc/net/dev >> $INFO_FILE 2>/dev/null

echo -e "\n=== WIRELESS INFO ===" >> $INFO_FILE
cat /proc/net/wireless >> $INFO_FILE 2>/dev/null

echo -e "\n=== NF5200 DRIVER INFO ===" >> $INFO_FILE
find /proc/net/nf5200 -type f 2>/dev/null | while read file; do
    echo "--- $file ---" >> $INFO_FILE
    cat "$file" >> $INFO_FILE 2>/dev/null
done

echo -e "\n=== MODULES ===" >> $INFO_FILE
cat /proc/modules >> $INFO_FILE 2>/dev/null

echo -e "\n=== MOUNTS ===" >> $INFO_FILE
cat /proc/mounts >> $INFO_FILE 2>/dev/null

echo "System info saved to $INFO_FILE"