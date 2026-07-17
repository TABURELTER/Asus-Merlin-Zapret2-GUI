#!/bin/sh
# install.sh - Installer for Asus-Merlin-Zapret2-GUI

ADDON_DIR="/jffs/addons/zapret2-gui"
SRC_DIR="$(dirname "$(readlink -f "$0")")"

echo "Installing Asus-Merlin-Zapret2-GUI..."

mkdir -p "$ADDON_DIR/lib"
cp -f "$SRC_DIR/zapret2-gui.sh" "$ADDON_DIR/"
cp -f "$SRC_DIR/zapret2-gui.asp" "$ADDON_DIR/"
cp -f "$SRC_DIR/lib/"*.sh "$ADDON_DIR/lib/"

chmod +x "$ADDON_DIR/zapret2-gui.sh"
for f in "$ADDON_DIR/lib/"*.sh; do
    chmod +x "$f" 2>/dev/null
done

# AsusWRT-Merlin hooks
SERVICES_START="/jffs/scripts/services-start"
SERVICE_EVENT_END="/jffs/scripts/service-event-end"
SERVICE_EVENT="/jffs/scripts/service-event"

Inject_Hook() {
    local hook_file="$1"
    local command="$2"
    
    if [ ! -f "$hook_file" ]; then
        echo "#!/bin/sh" > "$hook_file"
        chmod +x "$hook_file"
    fi
    
    if ! grep -q "$command" "$hook_file"; then
        echo "$command" >> "$hook_file"
    fi
}

echo "Injecting hooks..."
Inject_Hook "$SERVICES_START" "${ADDON_DIR}/zapret2-gui.sh mount"
Inject_Hook "$SERVICE_EVENT_END" "${ADDON_DIR}/zapret2-gui.sh mount"

# Hook for apply.cgi triggers
if [ ! -f "$SERVICE_EVENT" ]; then
    echo "#!/bin/sh" > "$SERVICE_EVENT"
    chmod +x "$SERVICE_EVENT"
fi

if ! grep -q "restart_zapret2gui_apply" "$SERVICE_EVENT"; then
    cat << 'EOF' >> "$SERVICE_EVENT"

if [ "$1" = "restart_zapret2gui_apply" ]; then
    /jffs/addons/zapret2-gui/zapret2-gui.sh apply &
fi
EOF
fi

echo "Mounting WebUI..."
"$ADDON_DIR/zapret2-gui.sh" mount

echo "Installation complete!"
