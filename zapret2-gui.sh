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
        z2gui_status)
            Action_Generate_Status
            ;;
    esac
}

Action_Generate_Status() {
    local pid
    pid=$(pidof nfqws2 | awk '{print $1}')
    
    local status="stopped"
    local cpu_ram="N/A"
    local iptables_count=0
    
    if [ -n "$pid" ]; then
        status="running"
        # Get CPU and RAM using ps/top. Busybox ps might differ, top -n1 -p PID is safer
        # Let's just use top -n1 | grep PID if we can, or just basic ps output
        # Format of ps: PID USER       VSZ STAT COMMAND
        local ps_out
        ps_out=$(ps -w | grep -E "^[ ]*${pid} " | head -n 1)
        if [ -n "$ps_out" ]; then
            # Extract VSZ (virtual size)
            local vsz
            vsz=$(echo "$ps_out" | awk '{print $3}')
            cpu_ram="${vsz} KB RAM"
        fi
        
        # Count iptables hooks
        iptables_count=$(iptables-save | grep -c "NFQUEUE.*--queue-num 300")
    fi
    
    cat <<EOF > "/www/user/zapret-status.asp"
{
  "status": "${status}",
  "pid": "${pid}",
  "cpu_ram": "${cpu_ram}",
  "iptables_count": "${iptables_count}"
}
EOF
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
    # We use a simple key-value plaintext payload now to avoid JSON quoting issues
    local raw
    # Convert base64url back to standard base64 (replace - with +, _ with /)
    local b64_std
    b64_std=$(echo "$b64_payload" | tr '_-' '/+')
    # Add padding if needed
    while [ $((${#b64_std} % 4)) -ne 0 ]; do b64_std="${b64_std}="; done

    if command -v openssl >/dev/null 2>&1; then
        raw=$(echo "$b64_std" | openssl base64 -d -A 2>/dev/null)
    else
        raw=$(echo "$b64_std" | base64 -d 2>/dev/null)
    fi
    
    # Extract fields
    local enable
    enable=$(echo "$raw" | grep "^enable=" | cut -d= -f2-)
    local mode
    mode=$(echo "$raw" | grep "^mode=" | cut -d= -f2-)
    local ports
    ports=$(echo "$raw" | grep "^ports=" | cut -d= -f2-)
    local custom_opt
    custom_opt=$(echo "$raw" | grep "^custom_opt=" | cut -d= -f2- | sed 's/@@NL@@/\n/g')
    
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
