#!/bin/sh

# System Metrics Logger
# Logs timestamp, CPU%, Memory%, and Temperature in CSV format

# Configuration
LOG_FILE="system_metrics.csv"
INTERVAL=5  # seconds between measurements
TEMP_SENSOR="/sys/class/thermal/thermal_zone0/temp"  # Common path for CPU temp

# Function to get CPU usage percentage
get_cpu_usage() {
    # Get first CPU reading from /proc/stat
    cpu_line=$(grep "^cpu " /proc/stat)
    
    # Extract CPU times using awk
    user=$(echo "$cpu_line" | awk '{print $2}')
    nice=$(echo "$cpu_line" | awk '{print $3}')
    system=$(echo "$cpu_line" | awk '{print $4}')
    idle=$(echo "$cpu_line" | awk '{print $5}')
    iowait=$(echo "$cpu_line" | awk '{print $6}')
    irq=$(echo "$cpu_line" | awk '{print $7}')
    softirq=$(echo "$cpu_line" | awk '{print $8}')
    steal=$(echo "$cpu_line" | awk '{print $9}')
    
    # Handle missing values (set to 0 if empty)
    iowait=${iowait:-0}
    irq=${irq:-0}
    softirq=${softirq:-0}
    steal=${steal:-0}
    
    # Calculate totals for first reading
    idle_time1=$((idle + iowait))
    total_time1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    
    # Short sleep for sampling
    sleep 0.1
    
    # Get second CPU reading
    cpu_line2=$(grep "^cpu " /proc/stat)
    user2=$(echo "$cpu_line2" | awk '{print $2}')
    nice2=$(echo "$cpu_line2" | awk '{print $3}')
    system2=$(echo "$cpu_line2" | awk '{print $4}')
    idle2=$(echo "$cpu_line2" | awk '{print $5}')
    iowait2=$(echo "$cpu_line2" | awk '{print $6}')
    irq2=$(echo "$cpu_line2" | awk '{print $7}')
    softirq2=$(echo "$cpu_line2" | awk '{print $8}')
    steal2=$(echo "$cpu_line2" | awk '{print $9}')
    
    iowait2=${iowait2:-0}
    irq2=${irq2:-0}
    softirq2=${softirq2:-0}
    steal2=${steal2:-0}
    
    # Calculate totals for second reading
    idle_time2=$((idle2 + iowait2))
    total_time2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
    
    # Calculate deltas
    idle_delta=$((idle_time2 - idle_time1))
    total_delta=$((total_time2 - total_time1))
    
    # Calculate CPU usage percentage
    if [ $total_delta -gt 0 ]; then
        cpu_usage=$((100 * (total_delta - idle_delta) / total_delta))
    else
        cpu_usage=0
    fi
    
    echo $cpu_usage
}

# Function to get memory usage percentage
get_memory_usage() {
    # Parse /proc/meminfo
    local mem_total=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
    local mem_available=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')
    
    # If MemAvailable is not available, calculate from MemFree + Buffers + Cached
    if [ -z "$mem_available" ]; then
        local mem_free=$(grep "MemFree:" /proc/meminfo | awk '{print $2}')
        local buffers=$(grep "Buffers:" /proc/meminfo | awk '{print $2}')
        local cached=$(grep "Cached:" /proc/meminfo | awk '{print $2}')
        mem_available=$((mem_free + buffers + cached))
    fi
    
    local mem_used=$((mem_total - mem_available))
    local mem_percentage=$((100 * mem_used / mem_total))
    
    echo $mem_percentage
}

# Function to get temperature
get_temperature() {
    temp="N/A"
    
    # Try ipcinfo command first
    if command -v ipcinfo >/dev/null 2>&1; then
        # Extract temperature from ipcinfo --temp output
        temp=$(ipcinfo --temp 2>/dev/null | grep -o '[0-9]*\.[0-9]*' | head -1)
        if [ -z "$temp" ]; then
            # Try to get integer temperature if decimal not found
            temp=$(ipcinfo --temp 2>/dev/null | grep -o '[0-9]*°C' | grep -o '[0-9]*' | head -1)
            if [ -z "$temp" ]; then
                # Try to extract just numbers from the output
                temp=$(ipcinfo --temp 2>/dev/null | grep -o '[0-9]*' | head -1)
            fi
        fi
    fi
    
    # Fallback to thermal zones if ipcinfo failed
    if [ "$temp" = "N/A" ] || [ -z "$temp" ]; then
        if [ -f "$TEMP_SENSOR" ]; then
            # Temperature in millidegrees Celsius
            temp=$(cat "$TEMP_SENSOR")
            temp=$((temp / 1000))
        elif [ -f "/sys/class/hwmon/hwmon0/temp1_input" ]; then
            # Alternative hwmon path
            temp=$(cat "/sys/class/hwmon/hwmon0/temp1_input")
            temp=$((temp / 1000))
        elif [ -f "/sys/class/hwmon/hwmon1/temp1_input" ]; then
            # Another alternative hwmon path
            temp=$(cat "/sys/class/hwmon/hwmon1/temp1_input")
            temp=$((temp / 1000))
        fi
    fi
    
    echo $temp
}

# Function to create CSV header
create_header() {
    echo "timestamp,seconds_since_start,cpu_percent,memory_percent,temperature_c" > "$LOG_FILE"
}

# Function to log metrics
log_metrics() {
    start_time=$1
    current_time=$(date +%s)
    seconds_elapsed=$((current_time - start_time))
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cpu_percent=$(get_cpu_usage)
    memory_percent=$(get_memory_usage)
    temperature=$(get_temperature)
    
    echo "$timestamp,$seconds_elapsed,$cpu_percent,$memory_percent,$temperature" >> "$LOG_FILE"
    
    # Also display to console
    printf "Time: %s | Elapsed: %ds | CPU: %s%% | Memory: %s%% | Temp: %s°C\n" \
           "$timestamp" "$seconds_elapsed" "$cpu_percent" "$memory_percent" "$temperature"
}

# Function to handle cleanup on exit
cleanup() {
    echo ""
    echo "Logging stopped. Data saved to $LOG_FILE"
    exit 0
}

# Main function
main() {
    echo "System Metrics Logger"
    echo "===================="
    echo "Logging to: $LOG_FILE"
    echo "Interval: ${INTERVAL} seconds"
    echo "Press Ctrl+C to stop logging"
    echo ""
    
    # Set up signal handling
    trap cleanup INT TERM
    
    # Create CSV header
    create_header
    
    # Record start time
    start_time=$(date +%s)
    
    # Main logging loop
    while true; do
        log_metrics $start_time
        sleep $INTERVAL
    done
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        -f|--file)
            LOG_FILE="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate interval - simple check for busybox
case $INTERVAL in
    ''|*[!0-9]*) 
        echo "Error: Interval must be a positive integer"
        exit 1
        ;;
    *)
        if [ "$INTERVAL" -lt 1 ]; then
            echo "Error: Interval must be a positive integer"
            exit 1
        fi
        ;;
esac

# Run the main function
main