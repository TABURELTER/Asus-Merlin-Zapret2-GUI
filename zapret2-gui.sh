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

Action_Event() {
    local evt="$1"
    local payload_file="/tmp/.zapret2gui.payload"
    
    case "$evt" in
        z2gui_start)
            rm -f "$payload_file"
            ;;
        z2gui_chk_*)
            local chunk="${evt#z2gui_chk_}"
            echo -n "$chunk" >> "$payload_file"
            ;;
        z2gui_apply)
            Action_Apply "$payload_file"
            ;;
    esac
}

Action_Apply() {
    local payload_file="$1"
    
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
    
    # decode base64url. Note: busybox base64 might need -d. Using openssl or tr+base64.
    local json
    # Convert base64url back to standard base64 (replace - with +, _ with /)
    local b64_std
    b64_std=$(echo "$b64_payload" | tr '_-' '/+')
    # Add padding if needed
    while [ $((${#b64_std} % 4)) -ne 0 ]; do b64_std="${b64_std}="; done

    if command -v openssl >/dev/null 2>&1; then
        json=$(echo "$b64_std" | openssl base64 -d -A 2>/dev/null)
    else
        json=$(echo "$b64_std" | base64 -d 2>/dev/null)
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
    event) Action_Event "$2" ;;
    *) echo "Usage: $0 {mount|unmount|status|event}"; exit 1 ;;
esac
