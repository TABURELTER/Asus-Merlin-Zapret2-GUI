#!/bin/sh
# install.sh - Installer for Asus-Merlin-Zapret2-GUI

# Terminal Colors
C_RESET="\033[0m"
C_INFO="\033[1;36m"
C_OK="\033[1;32m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"

Print_Info() { echo -e "${C_INFO}[INFO]${C_RESET} $1"; }
Print_OK()   { echo -e "${C_OK}[SUCCESS]${C_RESET} $1"; }
Print_Warn() { echo -e "${C_WARN}[WARN]${C_RESET} $1"; }
Print_Err()  { echo -e "${C_ERR}[ERROR]${C_RESET} $1"; }

echo -e "\n${C_INFO}=================================================${C_RESET}"
echo -e "${C_OK}    Asus-Merlin-Zapret2-GUI WebUI Installer      ${C_RESET}"
echo -e "${C_INFO}=================================================${C_RESET}\n"

ADDON_DIR="/jffs/addons/zapret2-gui"
REPO="TABURELTER/Asus-Merlin-Zapret2-GUI"
BRANCH="main"

Print_Info "Fetching latest version information from GitHub..."
# Fetch latest commit SHA to bypass cache and show version
LATEST_SHA=$(curl -s "https://api.github.com/repos/${REPO}/commits/${BRANCH}" | grep '"sha":' | head -n 1 | cut -d '"' -f 4 | cut -c 1-7)

if [ -n "$LATEST_SHA" ]; then
    Print_OK "Found latest version: ${LATEST_SHA}"
else
    Print_Warn "Failed to fetch commit SHA. Proceeding with default branch."
fi

# Append timestamp to bypass CDN caching
TAR_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz?t=$(date +%s)"

Print_Info "Downloading files from ${REPO}..."

mkdir -p "$ADDON_DIR/lib"
TMP_DIR="/tmp/zapret2-gui-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if ! curl -L -s "$TAR_URL" | tar -xz -C "$TMP_DIR"; then
    Print_Err "Failed to download or extract the repository archive."
    rm -rf "$TMP_DIR"
    exit 1
fi

EXTRACTED_DIR="${TMP_DIR}/Asus-Merlin-Zapret2-GUI-${BRANCH}"

if [ ! -d "$EXTRACTED_DIR" ]; then
    Print_Err "Repository directory not found after extraction."
    rm -rf "$TMP_DIR"
    exit 1
fi

Print_Info "Installing files to ${ADDON_DIR}..."
cp -f "$EXTRACTED_DIR/zapret2-gui.sh" "$ADDON_DIR/"
cp -f "$EXTRACTED_DIR/zapret2-gui.asp" "$ADDON_DIR/"
cp -f "$EXTRACTED_DIR/lib/"*.sh "$ADDON_DIR/lib/"
rm -rf "$TMP_DIR"

Print_Info "Checking for zapret core installation..."
ZAPRET_DIR="/opt/zapret"
if [ ! -x "$ZAPRET_DIR/init.d/sysv/zapret" ]; then
    Print_Warn "Zapret core not found in $ZAPRET_DIR. Attempting automatic installation..."
    
    # Check if /opt is writable
    if touch /opt/.zapret_test_write 2>/dev/null; then
        rm -f /opt/.zapret_test_write
        
        ZAPRET_TMP="/tmp/zapret-install"
        rm -rf "$ZAPRET_TMP"
        mkdir -p "$ZAPRET_TMP"
        
        Print_Info "Downloading bol-van/zapret repository..."
        if curl -L -s "https://github.com/bol-van/zapret/archive/refs/heads/master.tar.gz" | tar -xz -C "$ZAPRET_TMP"; then
            Print_Info "Extracting and placing into $ZAPRET_DIR..."
            rm -rf "$ZAPRET_DIR"
            mv "$ZAPRET_TMP/zapret-master" "$ZAPRET_DIR"
            
            Print_Info "Installing binaries for your architecture..."
            if sh "$ZAPRET_DIR/install_bin.sh"; then
                Print_OK "Zapret core binaries installed successfully."
                
                # Create default config to enable it
                if [ ! -f "$ZAPRET_DIR/config" ]; then
                    cp "$ZAPRET_DIR/config.default" "$ZAPRET_DIR/config"
                    sed -i 's/^NFQWS_ENABLE=.*/NFQWS_ENABLE=1/' "$ZAPRET_DIR/config"
                fi
                
                # Ensure hostlists exist so GUI doesn't fail
                mkdir -p "$ZAPRET_DIR/ipset"
                touch "$ZAPRET_DIR/ipset/zapret-hosts-user.txt"
                touch "$ZAPRET_DIR/ipset/zapret-hosts-user-exclude.txt"
                
                Print_OK "Zapret core setup complete! The GUI will now control it."
            else
                Print_Err "Failed to install Zapret core binaries."
            fi
        else
            Print_Err "Failed to download bol-van/zapret."
        fi
        rm -rf "$ZAPRET_TMP"
    else
        Print_Err "Directory /opt is not writable! Cannot auto-install zapret core."
        Print_Warn "Please plug in a USB drive and install Entware (via amtm) first."
    fi
else
    Print_OK "Zapret core is already installed in $ZAPRET_DIR."
fi


Print_Info "Setting file permissions..."
chmod +x "$ADDON_DIR/zapret2-gui.sh"
for f in "$ADDON_DIR/lib/"*.sh; do
    chmod +x "$f"
done

Print_Info "Injecting AsusWRT-Merlin system hooks..."
SERVICE_EVENT="/jffs/scripts/service-event"
SERVICES_START="/jffs/scripts/services-start"

Inject_Hook() {
    local target="$1"
    local cmd="$2"
    if [ ! -f "$target" ]; then
        echo "#!/bin/sh" > "$target"
        chmod +x "$target"
    fi
    if ! grep -q "$cmd" "$target"; then
        echo "$cmd" >> "$target"
    fi
}

Inject_Hook "$SERVICES_START" "${ADDON_DIR}/zapret2-gui.sh mount"

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

Print_Info "Mounting WebUI..."
"$ADDON_DIR/zapret2-gui.sh" mount

echo ""
Print_OK "Installation complete! The WebUI Addon is now active."
Print_Info "Please refresh your router's Web Interface to see the 'Zapret2' tab."
echo -e "${C_INFO}=================================================${C_RESET}\n"
