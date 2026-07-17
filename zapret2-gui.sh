#!/bin/sh
# zapret2-gui.sh - Main dispatcher for Asus-Merlin-Zapret2-GUI

# Hardcode ADDON_DIR since readlink -f can fail in some busybox environments
ADDON_DIR="/jffs/addons/zapret2-gui"
export PATH="/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin:$PATH"

. "${ADDON_DIR}/lib/merlin.sh"
. "${ADDON_DIR}/lib/config.sh"
. "${ADDON_DIR}/lib/strategy.sh"
. "${ADDON_DIR}/lib/status.sh"
. "${ADDON_DIR}/lib/safe_apply.sh"

Action_Mount() {
    Merlin_Mount "$ADDON_DIR"
}

Action_Unmount() {
    Merlin_Unmount
}

Action_Status() {
    Get_Status
}

Action_Apply() {
    local payload_file="/www/user/.zapret2gui.apply"
    
    if [ ! -f "$payload_file" ]; then
        echo "Error: Payload file not found."
        return 1
    fi
    
    local b64_payload
    b64_payload=$(cat "$payload_file" 2>/dev/null)
    
    if [ -z "$b64_payload" ]; then
        echo "Error: Payload is empty."
        return 1
    fi
    
    # decode base64. Note: busybox base64 might need -d. Using openssl or base64.
    local json
    if command -v openssl >/dev/null 2>&1; then
        json=$(echo "$b64_payload" | openssl base64 -d -A 2>/dev/null)
    else
        json=$(echo "$b64_payload" | base64 -d 2>/dev/null)
    fi
    
    # Parse JSON (basic string matching, no jq)
    local enable
    enable=$(echo "$json" | sed -n 's/.*"enable":"\([^"]*\)".*/\1/p')
    local mode
    mode=$(echo "$json" | sed -n 's/.*"mode":"\([^"]*\)".*/\1/p')
    local ports
    ports=$(echo "$json" | sed -n 's/.*"ports":"\([^"]*\)".*/\1/p')
    local custom_opt
    custom_opt=$(echo "$json" | sed -n 's/.*"custom_opt":"\([^"]*\)".*/\1/p')
    
    local opt
    opt=$(Strategy_Generate_Opt "$mode" "$ports" "$custom_opt")
    
    # Generate the config block
    # We use printf to preserve newlines safely
    local block
    block=$(printf "NFQWS2_ENABLE=%s\nNFQWS2_PORTS_TCP=%s\nNFQWS2_OPT=\"\n%s\n\"\n" "$enable" "$ports" "$opt")
    
    # Apply to config
    echo "$block" | Config_Apply_Block
    
    # Trigger safe apply
    Safe_Apply "$opt"
    
    # Clean up payload
    rm -f "$payload_file"
}

case "$1" in
    mount) Action_Mount ;;
    unmount) Action_Unmount ;;
    status) Action_Status ;;
    apply) Action_Apply ;;
    *) echo "Usage: $0 {mount|unmount|status|apply}"; exit 1 ;;
esac
