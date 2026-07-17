#!/bin/sh
# lib/safe_apply.sh - Safe configuration apply and rollback

# Note: Assumes lock.sh and status.sh are already sourced by dispatcher

ZAPRET_INIT="/opt/zapret2/init.d/sysv/zapret2"
ZAPRET_CONFIG="/opt/zapret2/config"
ZAPRET_CONFIG_BAK="/opt/zapret2/config.bak-gui"

Safe_Apply() {
    local target_opt="$1"
    
    if ! Lock_Acquire; then
        echo "Failed to acquire lock, another operation is in progress."
        return 1
    fi
    
    # Backup
    if [ -f "$ZAPRET_CONFIG" ]; then
        cp -f "$ZAPRET_CONFIG" "$ZAPRET_CONFIG_BAK"
    fi
    
    # Restart zapret2 with a timeout (e.g. 30 seconds)
    echo "Restarting zapret2..."
    if ! Run_With_Timeout 30 "$ZAPRET_INIT" restart; then
        echo "Restart command timed out or failed!"
        Rollback
        Lock_Release
        return 1
    fi
    
    # Health check
    # Wait a moment for nfqws to fully initialize
    sleep 2
    if ! Health_Check "$target_opt"; then
        echo "Health check failed! Rolling back..."
        Rollback
        Lock_Release
        return 1
    fi
    
    echo "Apply successful."
    Lock_Release
    return 0
}

Rollback() {
    echo "Restoring configuration from backup..."
    if [ -f "$ZAPRET_CONFIG_BAK" ]; then
        cp -f "$ZAPRET_CONFIG_BAK" "$ZAPRET_CONFIG"
    fi
    
    echo "Restarting zapret2 to restore previous state..."
    Run_With_Timeout 30 "$ZAPRET_INIT" restart
}
