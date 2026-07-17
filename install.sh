#!/bin/sh
# install.sh - Installer for Asus-Merlin-Zapret2-GUI

ADDON_DIR="/jffs/addons/zapret2-gui"
REPO="TABURELTER/Asus-Merlin-Zapret2-GUI"
BRANCH="main"
TAR_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

echo "Installing Asus-Merlin-Zapret2-GUI from ${REPO}..."

mkdir -p "$ADDON_DIR/lib"
TMP_DIR="/tmp/zapret2-gui-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "Downloading files..."
curl -L -s "$TAR_URL" | tar -xz -C "$TMP_DIR"

EXTRACTED_DIR="${TMP_DIR}/Asus-Merlin-Zapret2-GUI-${BRANCH}"

if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "Error: Failed to download or extract the repository."
    rm -rf "$TMP_DIR"
    exit 1
fi

cp -f "$EXTRACTED_DIR/zapret2-gui.sh" "$ADDON_DIR/"
cp -f "$EXTRACTED_DIR/zapret2-gui.asp" "$ADDON_DIR/"
cp -f "$EXTRACTED_DIR/lib/"*.sh "$ADDON_DIR/lib/"
rm -rf "$TMP_DIR"

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

if ! grep -q "z2gui_" "$SERVICE_EVENT"; then
    cat << 'EOF' >> "$SERVICE_EVENT"

case "$1" in
    z2gui_*) /jffs/addons/zapret2-gui/zapret2-gui.sh event "$1" & ;;
esac
EOF
fi

echo "Mounting WebUI..."
"$ADDON_DIR/zapret2-gui.sh" mount

echo "Installation complete!"
