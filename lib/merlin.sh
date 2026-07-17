#!/bin/sh
# lib/merlin.sh - WebUI integration logic

Merlin_Mount() {
    local addon_dir="$1"
    local asp_name="zapret2-gui.asp"
    local menutree="/www/require/modules/menuTree.js"
    local menutree_tmp="/tmp/menuTree.js"
    local anchor="Advanced_Wireless_Survey.asp"

    # Copy the ASP page to /www/user (which is memory-backed and accessible via HTTP)
    cp -f "${addon_dir}/${asp_name}" "/www/user/${asp_name}" 2>/dev/null
    
    # Inject into menuTree.js via bind mount
    cp -f "$menutree" "$menutree_tmp"
    if ! grep -q "zapret2-gui.asp" "$menutree_tmp"; then
        # Insert our menu item right after the anchor
        sed -i -e "/${anchor}/a \\
        {url: 'zapret2-gui.asp', title: 'Zapret2'}," "$menutree_tmp"
        
        # Bind mount to override the read-only file
        mount -o bind "$menutree_tmp" "$menutree"
    fi
}

Merlin_Unmount() {
    local menutree="/www/require/modules/menuTree.js"
    local asp_name="zapret2-gui.asp"

    if mount | grep -q "$menutree"; then
        umount "$menutree" 2>/dev/null
    fi
    rm -f "/tmp/menuTree.js"
    rm -f "/www/user/${asp_name}"
}
