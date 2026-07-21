#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ -z "${TLP_UI_INSTALL_DIR:-}" ]]; then
    TLP_UI_INSTALL_DIR="$INSTALL_DIR/tlp-ui"
fi

REPO_URL="https://github.com/d4nj1/TLPUI.git"
LAUNCHER_PATH="/usr/local/bin/tlp-ui"

ICON_SOURCE="$PAYLOAD_DIR/tlp-ui.png"
ICON_THEME_DIR="/usr/share/icons/hicolor"
ICON_PATH="$ICON_THEME_DIR/512x512/apps/tlp-ui.png"

APPLICATION_DIR="/usr/share/applications"
DESKTOP_FILE="$APPLICATION_DIR/tlp-ui.desktop"

if [[ ! -f "$ICON_SOURCE" ]]; then
    log_error "[$CANONICAL_ID] Application icon not found: $ICON_SOURCE"

    exit 1
fi

#
# Install runtime dependencies
#
log_info "[$CANONICAL_ID] Installing Python and GTK runtime dependencies"

if ! apt_install \
    python3-gi \
    python3-yaml \
    python3-toml \
    gir1.2-gtk-3.0
then
    log_error "[$CANONICAL_ID] Failed to install Python or GTK runtime dependencies"

    exit 2
fi

if ! python3 -c 'import gi, yaml, toml' >/dev/null 2>&1; then
    log_error "[$CANONICAL_ID] Failed to load the required Python modules: gi, yaml and toml"

    exit 3
fi

#
# Clone TLPUI
#
log_info "[$CANONICAL_ID] Installing to $TLP_UI_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$TLP_UI_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if [[ -f "$TLP_UI_INSTALL_DIR/tlpui/__main__.py" ]]; then
    log_warn "[$CANONICAL_ID] Target directory already contains TLPUI, skipping clone: $TLP_UI_INSTALL_DIR"
else
    if [[ -e "$TLP_UI_INSTALL_DIR" ]]; then
        log_error "[$CANONICAL_ID] Target exists but does not contain a valid TLPUI checkout: $TLP_UI_INSTALL_DIR"

        exit 4
    fi

    INSTALL_PARENT_DIR="$(dirname -- "$TLP_UI_INSTALL_DIR")"

    if ! $SUDO_CMD mkdir -p "$INSTALL_PARENT_DIR"; then
        log_error "[$CANONICAL_ID] Failed to create install directory: $INSTALL_PARENT_DIR"

        exit 5
    fi

    if ! $SUDO_CMD git clone \
        --depth 1 \
        "$REPO_URL" \
        "$TLP_UI_INSTALL_DIR"
    then
        log_error "[$CANONICAL_ID] Failed to clone repository: $REPO_URL"

        exit 6
    fi
fi

#
# Create command launcher
#
log_info "[$CANONICAL_ID] Creating launcher: $LAUNCHER_PATH"

printf -v quoted_install_dir '%q' "$TLP_UI_INSTALL_DIR"

if ! sudo tee "$LAUNCHER_PATH" >/dev/null <<EOF
#!/usr/bin/env bash

cd $quoted_install_dir || exit 1
exec python3 -m tlpui "\$@"
EOF
then
    log_error "[$CANONICAL_ID] Failed to create launcher: $LAUNCHER_PATH"

    exit 7
fi

if ! sudo chmod 0755 "$LAUNCHER_PATH"; then
    log_error "[$CANONICAL_ID] Failed to make launcher executable: $LAUNCHER_PATH"

    exit 8
fi

#
# Install application icon
#
log_info "[$CANONICAL_ID] Installing application icon: $ICON_PATH"

if ! sudo install -Dm0644 "$ICON_SOURCE" "$ICON_PATH"; then
    log_error "[$CANONICAL_ID] Failed to install application icon: $ICON_PATH"

    exit 9
fi

#
# Install desktop entry
#
log_info "[$CANONICAL_ID] Installing desktop file: $DESKTOP_FILE"

if ! sudo mkdir -p "$APPLICATION_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create desktop application directory: $APPLICATION_DIR"

    exit 10
fi

if ! sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=TLP UI
GenericName=Power Management
Comment=Configure TLP power management
Exec=tlp-ui
TryExec=tlp-ui
Icon=tlp-ui
Terminal=false
Categories=Settings;HardwareSettings;GTK;
Keywords=Battery;Power;Laptop;TLP;
StartupWMClass=Tlp-UI
EOF
then
    log_error "[$CANONICAL_ID] Failed to install desktop file: $DESKTOP_FILE"

    exit 11
fi

if ! sudo chmod 0644 "$DESKTOP_FILE"; then
    log_error "[$CANONICAL_ID] Failed to set desktop file permissions: $DESKTOP_FILE"

    exit 12
fi

#
# Refresh desktop caches when supported
#
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    log_info "[$CANONICAL_ID] Refreshing icon cache"

    if ! sudo gtk-update-icon-cache -f -t "$ICON_THEME_DIR"; then
        log_warn "[$CANONICAL_ID] Failed to refresh the icon cache"
    fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    log_info "[$CANONICAL_ID] Refreshing desktop application database"

    if ! sudo update-desktop-database "$APPLICATION_DIR"; then
        log_warn "[$CANONICAL_ID] Failed to refresh the desktop application database"
    fi
fi

log_info "[$CANONICAL_ID] Installation completed successfully"
