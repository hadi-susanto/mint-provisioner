#!/usr/bin/env bash

#
# Installs kitty from a previously downloaded .txz archive.
#

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$CANONICAL_ID] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${KITTY_INSTALL_DIR:-}" ]]; then
    KITTY_INSTALL_DIR="$INSTALL_DIR/kitty"
fi

log_info "[$CANONICAL_ID] Extracting content to $KITTY_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$KITTY_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$KITTY_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $KITTY_INSTALL_DIR"

    exit 3
fi

# Extract. Using -C to change directory.
if ! $SUDO_CMD tar --overwrite -xJf "$ARCHIVE_FILE" -C "$KITTY_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 4
fi

log_info "[$CANONICAL_ID] Creating symbolic links"
if [[ "$KITTY_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$KITTY_INSTALL_DIR/bin/kitty"
    symlink_binary "$CANONICAL_ID" "$KITTY_INSTALL_DIR/bin/kitten"
else
    log_info "[$CANONICAL_ID] Install directory matches symlink location, skipping symlink creation"
fi

if [[ -z "${KITTY_INSTALL_OPEN_HANDLER:-}" ]]; then
    KITTY_INSTALL_OPEN_HANDLER="false"
fi

log_info "[$CANONICAL_ID] Installing desktop files"
sudo mkdir -p /usr/share/applications
sudo cp "$KITTY_INSTALL_DIR/share/applications/kitty.desktop" /usr/share/applications/

if [[ "$KITTY_INSTALL_OPEN_HANDLER" == "true" ]]; then
    log_info "[$CANONICAL_ID] Installing kitty-open.desktop file"
    sudo cp "$KITTY_INSTALL_DIR/share/applications/kitty-open.desktop" /usr/share/applications/
else
    log_info "[$CANONICAL_ID] Skipping kitty-open.desktop file installation, to install please pass KITTY_INSTALL_OPEN_HANDLER=true"
fi

log_info "[$CANONICAL_ID] Updating paths in desktop files"
# Update the paths to the kitty and its icon in the kitty desktop file(s)
ICON_PATH="$KITTY_INSTALL_DIR/share/icons/hicolor/256x256/apps/kitty.png"
EXEC_PATH="$KITTY_INSTALL_DIR/bin/kitty"

sudo sed -i "s|Icon=kitty|Icon=$ICON_PATH|g" /usr/share/applications/kitty*.desktop
sudo sed -i "s|Exec=kitty|Exec=$EXEC_PATH|g" /usr/share/applications/kitty*.desktop

log_info "[$CANONICAL_ID] Updating xdg-terminals.list"
XDG_TERMINALS_LIST="$(get_user_home)/.config/xdg-terminals.list"
mkdir -p "${XDG_TERMINALS_LIST%/*}"
touch "$XDG_TERMINALS_LIST"

if ! grep -Fxq 'kitty.desktop' "$XDG_TERMINALS_LIST"; then
    echo 'kitty.desktop' >> "$XDG_TERMINALS_LIST"
fi

log_info "[$CANONICAL_ID] Installation completed successfully"
