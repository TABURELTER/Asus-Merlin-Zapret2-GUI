#!/bin/sh
# lib/merlin.sh - WebUI integration logic

[ -f /usr/sbin/helper.sh ] && . /usr/sbin/helper.sh

Merlin_Mount() {
    local addon_dir="$1"
    local asp_src="${addon_dir}/zapret2-gui.asp"
    local menutree="/www/require/modules/menuTree.js"
    local menutree_tmp="/tmp/menuTree.js"
    local anchor="Advanced_Wireless_Survey.asp"

    local page
    if type am_settings_get >/dev/null 2>&1; then
        page="$(am_settings_get zapret2gui_page 2>/dev/null)"
        if [ -z "$page" ]; then
            am_get_webui_page "$asp_src"
            if [ "$am_webui_page" = "none" ] || [ -z "$am_webui_page" ]; then
                echo "Error: no free user page slot for WebUI."
                return 1
            fi
            page="$am_webui_page"
            am_settings_set zapret2gui_page "$page"
        else
            cp -f "$asp_src" "/www/user/$page" 2>/dev/null
        fi
    else
        page="zapret2-gui.asp"
        cp -f "$asp_src" "/www/user/$page" 2>/dev/null
    fi

    # Unmount if already mounted to avoid copy failure
    umount "$menutree" 2>/dev/null
    [ -f "$menutree_tmp" ] || cp -f "$menutree" "$menutree_tmp"
    
    # Remove old entry if exists to prevent duplicates
    sed -i -e "/tabName: 'Zapret2'/d" "$menutree_tmp"
    
    # Inject our menu item right after the anchor using tabName (AsusWRT format)
    sed -i -e "/${anchor}/a \\
        {url: '${page}', tabName: 'Zapret2'}," "$menutree_tmp"
        
    mount -o bind "$menutree_tmp" "$menutree"
}

Merlin_Unmount() {
    local menutree="/www/require/modules/menuTree.js"
    
    local page
    if type am_settings_get >/dev/null 2>&1; then
        page="$(am_settings_get zapret2gui_page 2>/dev/null)"
    fi
    [ -z "$page" ] && page="zapret2-gui.asp"

    umount "$menutree" 2>/dev/null
    rm -f "/tmp/menuTree.js"
    rm -f "/www/user/${page}"
}
