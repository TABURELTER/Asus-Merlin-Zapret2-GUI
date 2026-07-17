#!/bin/sh
# lib/status.sh - Healthcheck and Status

Get_Status() {
    local running=0
    local process_check=0
    local iptables_check=0
    
    # 1. Check if process is running
    local pid
    pid=$(pidof tpws 2>/dev/null)
    if [ -n "$pid" ]; then
        process_check=1
    fi
    
    # 2. Check iptables for REDIRECT
    if iptables -t nat -L 2>/dev/null | grep -q "REDIRECT"; then
        iptables_check=1
    fi
    
    if [ "$process_check" -eq 1 ] && [ "$iptables_check" -eq 1 ]; then
        running=1
    fi
    
    # Simple JSON output
    echo "{"
    echo "  \"running\": $running,"
    echo "  \"process_check\": $process_check,"
    echo "  \"iptables_check\": $iptables_check,"
    if [ -n "$pid" ]; then
        echo "  \"pid\": \"$pid\""
    else
        echo "  \"pid\": null"
    fi
    echo "}"
}

Health_Check() {
    local target_opt="$1"
    
    # 1. Check if process is running
    local pid
    pid=$(pidof tpws 2>/dev/null)
    if [ -z "$pid" ]; then
        return 1
    fi
    
    # 2. Process exists, let's verify cmdline has some of our parameters
    # The /proc/<pid>/cmdline is null separated. 
    local cmdline
    if [ -f "/proc/$pid/cmdline" ]; then
        cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        
        # Check if one of the distinct arguments from target_opt is present
        # Extract the first --filter-tcp or --lua-desync
        local test_arg
        test_arg=$(echo "$target_opt" | grep -o -- '--lua-desync=[^ ]*' | head -n 1)
        if [ -n "$test_arg" ]; then
            if ! echo "$cmdline" | grep -q -e "$test_arg"; then
                return 1
            fi
        fi
    fi
    
    # 3. Check iptables
    if iptables -t nat -L 2>/dev/null | grep -q "REDIRECT"; then
        return 0
    else
        return 1
    fi
}
