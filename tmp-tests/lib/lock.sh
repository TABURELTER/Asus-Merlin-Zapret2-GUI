#!/bin/sh
# lib/lock.sh - Synchronization primitives for busybox

LOCK_DIR="/Users/tab/Downloads/Asus-Merlin-Zapret2-GUI/tmp-tests/.lock"

Lock_Acquire() {
    local ttl=90
    local lock_ts_file="${LOCK_DIR}/ts"
    
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        date +%s > "$lock_ts_file"
        return 0
    else
        # Lock exists, check for staleness
        if [ -f "$lock_ts_file" ]; then
            local ts
            ts=$(cat "$lock_ts_file" 2>/dev/null)
            local now
            now=$(date +%s)
            
            # If TS is empty or not a number, or expired, consider it stale
            if [ -z "$ts" ] || [ "$((now - ts))" -gt "$ttl" ] 2>/dev/null; then
                # Dead lock detected
                rm -rf "$LOCK_DIR"
                if mkdir "$LOCK_DIR" 2>/dev/null; then
                    date +%s > "$lock_ts_file"
                    return 0
                fi
            fi
        fi
        return 1
    fi
}

Lock_Release() {
    rm -rf "$LOCK_DIR"
}

Run_With_Timeout() {
    local timeout_secs="$1"
    shift
    
    "$@" &
    local pid=$!
    
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$i" -ge "$timeout_secs" ]; then
            kill -9 "$pid" 2>/dev/null
            return 124 # standard timeout exit code
        fi
        sleep 1
        i=$((i + 1))
    done
    
    wait "$pid"
    return $?
}
