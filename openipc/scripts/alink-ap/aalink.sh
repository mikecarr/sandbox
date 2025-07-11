#!/bin/sh
# aalink.sh - Adaptive link control with hardware detection
# Fixed version with proper cleanup and signal handling

# Configuration
IF=${WLAN_INTERFACE:-wlan0}
TARGET_IP=${PING_TARGET:-192.168.0.10}
API_URL=${API_ENDPOINT:-"http://127.0.0.1/api/v1/set?video0.bitrate=%d"}

# Logging options
VERBOSE=0
LOG_FILE=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --log|-l)
            LOG_FILE="$2"
            # Auto-enable verbose when log file is specified
            VERBOSE=1
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --verbose, -v     Enable verbose logging"
            echo "  --log FILE, -l    Enable verbose logging and write to FILE"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Rate control parameters
THR="-90 -85 -80 -70 -60 -30 -20 -10"
PR="6500 13000 19500 26000 39000 52000 58500 65000"
HYST=2

# State variables
mcs=0
cnt=0
PING_PID=""
RATE=""

# Logging function
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S'): $*"

    # Only log if verbose is enabled
    if [ "$VERBOSE" = "1" ]; then
        echo "$message" >&2

        # Also write to log file if specified and verbose is on
        if [ -n "$LOG_FILE" ]; then
            echo "$message" >> "$LOG_FILE"
        fi
    fi
}

# Error logging (always shown, optionally logged to file if verbose)
log_error() {
    echo "ERROR: $*" >&2

    # Only write to log file if verbose is enabled
    if [ "$VERBOSE" = "1" ] && [ -n "$LOG_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR: $*" >> "$LOG_FILE"
    fi
}

# Cleanup function
cleanup() {
    log "Shutting down aalink..."

    # Kill ping process if running
    if [ -n "$PING_PID" ]; then
        if kill -0 $PING_PID 2>/dev/null; then
            log "Stopping ping process (PID: $PING_PID)"
            kill $PING_PID 2>/dev/null

            # Wait a moment for graceful shutdown
            sleep 1

            # Force kill if still running
            if kill -0 $PING_PID 2>/dev/null; then
                log "Force killing ping process"
                kill -KILL $PING_PID 2>/dev/null
            fi
        fi
    fi

    # Clean up any leftover processes
    pkill -f "ping.*$TARGET_IP" 2>/dev/null

    # Clear OSD message
    echo "" > /tmp/MSPOSD.msg 2>/dev/null

    log "Cleanup complete"
    exit 0
}

# Signal handlers
trap cleanup TERM INT

# Hardware detection function
detect_wireless_hardware() {
    local driver=""
    local card

    log "Detecting wireless hardware..."

    for card in $(lsusb | awk '{print $6}' | uniq); do
        case "$card" in
            "0bda:8812" | "0bda:881a" | "0b05:17d2" | "2357:0101" | "2604:0012")
                driver="88XXau"
                log "Detected 88XXau compatible device: $card"
                ;;
            "0bda:a81a")
                driver="8812eu"
                log "Detected 8812eu compatible device: $card"
                ;;
            "0bda:f72b" | "0bda:b733")
                driver="8733bu"
                log "Detected 8733bu compatible device: $card"
                ;;
        esac
    done

    if [ -z "$driver" ]; then
        log_error "Wireless module not detected!"
        return 1
    fi

    if [ "$driver" != "8812eu" ]; then
        log_error "Driver $driver currently not supported (only 8812eu)"
        return 1
    fi

    log "Hardware detection successful: $driver"
    return 0
}

# Validate environment
validate_environment() {
    log "Validating environment..."

    # Check if interface exists
    if ! ip link show "$IF" >/dev/null 2>&1; then
        log_error "Interface $IF not found"
        return 1
    fi

    # Set rate control path based on detected hardware
    RATE="/proc/net/rtl88x2eu/$IF/rate_ctl"

    # Check if rate control file exists
    if [ ! -f "$RATE" ]; then
        log_error "Rate control file $RATE not found"
        return 1
    fi

    # Check if iw command is available
    if ! command -v iw >/dev/null 2>&1; then
        log_error "iw command not found"
        return 1
    fi

    log "Environment validation successful"
    log "Interface: $IF"
    log "Rate control: $RATE"
    log "Target IP: $TARGET_IP"
    log "API URL: $API_URL"

    return 0
}

# Start ping keepalive
start_ping_keepalive() {
    log "Starting ping keepalive to $TARGET_IP..."

    (
        while :; do
            ping -c1 -W1 "$TARGET_IP" >/dev/null 2>&1
            sleep 0.05
        done
    ) &

    PING_PID=$!
    log "Ping keepalive started (PID: $PING_PID)"
}

# Function to get RSSI
rssi() {
    iw dev "$IF" station dump 2>/dev/null | awk '/signal:/ {print $2; exit}'
}

# Function to get nth element from space-separated string
get() {
    echo "$1" | cut -d' ' -f$(($2 + 1))
}

# Function to set rate and bitrate
set_rate_and_bitrate() {
    local new_mcs=$1
    local pr kb code

    pr=$(get "$PR" $new_mcs)
    kb=$((pr * 2 / 3))   # THROUGHPUT calculation
    code=$(printf "0x%X" $((0x68C + new_mcs)))

    if [ $new_mcs -gt $mcs ]; then
        # Increasing rate: set wireless rate first, then API
        log "Increasing rate: MCS $mcs -> $new_mcs (${kb}kb/s)"
        if printf "%s\n" "$code" >"$RATE" 2>/dev/null; then
            sleep 0.05
            wget -qO- "$(printf "$API_URL" "$kb")" >/dev/null 2>&1
        else
            log_error "Failed to write to rate control file"
        fi
    else
        # Decreasing rate: set API first, then wireless rate
        log "Decreasing rate: MCS $mcs -> $new_mcs (${kb}kb/s)"
        wget -qO- "$(printf "$API_URL" "$kb")" >/dev/null 2>&1
        sleep 0.05
        if ! printf "%s\n" "$code" >"$RATE" 2>/dev/null; then
            log_error "Failed to write to rate control file"
        fi
    fi

    return $kb
}

# Function to update OSD
update_osd() {
    local current_mcs=$1
    local target_kb=$2
    local rssi_val=$3
    local target_mb

    target_mb=$(awk -v k="$target_kb" 'BEGIN{printf("%.1f",k/1000)}')
    echo "&L31&F20 MCS:$current_mcs | target:${target_mb}Mb | actual:&B | CPU:&C,&Tc | TX:&Wc&G8 | uplink-rssi:$rssi_val" > /tmp/MSPOSD.msg 2>/dev/null
}

# Main function
main() {
    log "Starting aalink adaptive link control..."

    # Detect and validate hardware
    if ! detect_wireless_hardware; then
        log_error "Hardware detection failed"
        exit 1
    fi

    # Validate environment
    if ! validate_environment; then
        log_error "Environment validation failed"
        exit 1
    fi

    # Start ping keepalive
    start_ping_keepalive

    log "Starting main control loop..."

    # Main control loop
    while :; do
        s=$(rssi) || {
            sleep 0.1
            continue
        }

        # Validate RSSI is a number
        if ! printf '%s\n' "$s" | grep -qE '^-?[0-9]+$'; then
            sleep 0.1
            continue
        fi

        next=$mcs
        thr_up=$(get "$THR" $((mcs+1))) && up_th=$((thr_up+HYST))
        thr_cur=$(get "$THR" $mcs) && dn_th=$((thr_cur-HYST))

        # Rate adaptation logic
        [ $mcs -lt 7 ] && [ "$s" -gt "$up_th" ] && next=$((mcs+1))
        [ "$s" -lt "$dn_th" ] && next=$((mcs-1))

        # Apply changes if needed
        if [ "$next" -ne "$mcs" ]; then
            set_rate_and_bitrate $next
            kb=$?
            mcs=$next
        else
            # Calculate current kb for OSD
            pr=$(get "$PR" $mcs)
            kb=$((pr * 2 / 3))
        fi

        # Update OSD every 5 iterations (0.5 seconds)
        if [ $((cnt % 5)) -eq 0 ]; then
            update_osd $mcs $kb $s
        fi

        cnt=$((cnt + 1))
        sleep 0.1
    done
}

# Start main function
main