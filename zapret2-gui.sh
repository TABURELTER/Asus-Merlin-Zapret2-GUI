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

Log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> /tmp/zapret2-gui.log
}

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
    local status="stopped"
    local pid=""
    
    if pidof nfqws >/dev/null; then
        status="running"
        pid=$(pidof nfqws | head -n 1)
    fi
    
    local cpu_ram="N/A"
    if [ -n "$pid" ]; then
        cpu_ram=$(top -b -n 1 | grep "^\s*$pid " | awk '{print "CPU: "$8"% / RAM: "$7"%"}')
    fi
    
    local iptables_count="0"
    if command -v iptables-save >/dev/null 2>&1; then
        iptables_count=$(iptables-save | grep -c "NFQUEUE.*--queue-num 300")
    fi
    
    local log_tail=""
    if [ -f "/tmp/zapret2-gui.log" ]; then
        log_tail=$(tail -n 20 /tmp/zapret2-gui.log | sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g; s/$/\\n/g' | tr -d '\n')
    fi
    
    cat <<EOF > "/www/user/zapret-status.asp"
{
  "status": "${status}",
  "pid": "${pid}",
  "cpu_ram": "${cpu_ram}",
  "iptables_count": "${iptables_count}",
  "log": "${log_tail}"
}
EOF
}

Action_Apply() {
    local payload_file="$1"
    Log "Action_Apply started."
    
    if [ ! -f "$payload_file" ]; then
        Log "Error: Payload file not found."
        return 1
    fi
    
    local b64_payload
    b64_payload=$(cat "$payload_file" 2>/dev/null)
    Log "Payload length: ${#b64_payload}"
    
    if [ -z "$b64_payload" ]; then
        Log "Error: Payload is empty."
        return 1
    fi
    
    local raw
    local b64_std
    b64_std=$(echo "$b64_payload" | tr '_-' '/+')
    while [ $((${#b64_std} % 4)) -ne 0 ]; do b64_std="${b64_std}="; done

    if command -v openssl >/dev/null 2>&1; then
        raw=$(echo "$b64_std" | openssl base64 -d -A 2>/dev/null)
    else
        raw=$(echo "$b64_std" | base64 -d 2>/dev/null)
    fi
    Log "Decoded raw payload length: ${#raw}"
    
    local enable
    enable=$(echo "$raw" | grep "^enable=" | cut -d= -f2-)
    local mode
    mode=$(echo "$raw" | grep "^mode=" | cut -d= -f2-)
    local ports
    ports=$(echo "$raw" | grep "^ports=" | cut -d= -f2-)
    local custom_opt
    custom_opt=$(echo "$raw" | grep "^custom_opt=" | cut -d= -f2- | sed 's/@@NL@@/\n/g')
    
    Log "Parsed -> enable=${enable}, mode=${mode}, ports=${ports}"
    
    local opt
    opt=$(Strategy_Generate_Opt "$mode" "$ports" "$custom_opt")
    Log "Generated NFQWS2_OPT: $opt"
    
    local block
    block=$(printf "NFQWS2_ENABLE=%s\nNFQWS2_PORTS_TCP=%s\nNFQWS2_OPT=\"\n%s\n\"\n" "$enable" "$ports" "$opt")
    
    Log "Applying config block..."
    echo "$block" | Config_Apply_Block
    
    Log "Triggering Safe_Apply..."
    Safe_Apply "$opt"
    Log "Safe_Apply complete."
    
    rm -f "$payload_file"
}

case "$1" in
    mount) Action_Mount ;;
    unmount) Action_Unmount ;;
    status) Action_Generate_Status ;;
    event) Action_Event "$2" ;;
    *) echo "Usage: $0 {mount|unmount|status|event}"; exit 1 ;;
esac
