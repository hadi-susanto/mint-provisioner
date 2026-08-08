#!/usr/bin/env bash
set -euo pipefail

#
# Installs kitty from a previously downloaded .txz archive.
#

source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit 1

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    tlog_error "install:$CANONICAL_ID" "Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${KITTY_INSTALL_DIR:-}" ]]; then
    KITTY_INSTALL_DIR="$INSTALL_DIR/kitty"
fi

tlog_info "install:$CANONICAL_ID" "Extracting content to $KITTY_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$KITTY_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$KITTY_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $KITTY_INSTALL_DIR"

    exit 3
fi

# Extract. Using -C to change directory.
if ! $SUDO_CMD tar --overwrite -xJf "$ARCHIVE_FILE" -C "$KITTY_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x \
    "$KITTY_INSTALL_DIR/bin/kitty" \
    "$KITTY_INSTALL_DIR/bin/kitten"
then
    tlog_error "install:$CANONICAL_ID" "Failed to make Kitty binaries executable"

    exit 5
fi

tlog_info "install:$CANONICAL_ID" "Creating symbolic links"
if [[ "$KITTY_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$KITTY_INSTALL_DIR/bin/kitty"
    symlink_binary "$CANONICAL_ID" "$KITTY_INSTALL_DIR/bin/kitten"
else
    tlog_info "install:$CANONICAL_ID" "Install directory matches symlink location, skipping symlink creation"
fi

KITTY_INSTALL_OPEN_HANDLER="${KITTY_INSTALL_OPEN_HANDLER:-false}"

tlog_info "install:$CANONICAL_ID" "Installing desktop files"

APPLICATION_DIR="/usr/share/applications"
desktop_files=("kitty.desktop")

if [[ "$KITTY_INSTALL_OPEN_HANDLER" == "true" ]]; then
    tlog_info "install:$CANONICAL_ID" "Installing kitty-open.desktop file"
    desktop_files+=("kitty-open.desktop")
else
    tlog_info "install:$CANONICAL_ID" "Skipping kitty-open.desktop file installation, to install please pass KITTY_INSTALL_OPEN_HANDLER=true"
fi

# Update the paths to the kitty and its icon in the kitty desktop file(s)
ICON_PATH="$KITTY_INSTALL_DIR/share/icons/hicolor/256x256/apps/kitty.png"
EXEC_PATH="$KITTY_INSTALL_DIR/bin/kitty"

if [[ ! -f "$ICON_PATH" ]]; then
    tlog_error "install:$CANONICAL_ID" "Kitty icon not found: $ICON_PATH"

    exit 6
fi

for desktop_file in "${desktop_files[@]}"; do
    desktop_source="$KITTY_INSTALL_DIR/share/applications/$desktop_file"
    desktop_target="$APPLICATION_DIR/$desktop_file"

    if [[ ! -f "$desktop_source" ]]; then
        tlog_error "install:$CANONICAL_ID" "Desktop file not found: $desktop_source"

        exit 7
    fi

    if ! sudo install -Dm0644 "$desktop_source" "$desktop_target"; then
        tlog_error "install:$CANONICAL_ID" "Failed to install desktop file: $desktop_target"

        exit 8
    fi

    tlog_info "install:$CANONICAL_ID" "Updating paths in $desktop_target"

    if ! sudo sed -i \
        -e "s|Icon=kitty|Icon=$ICON_PATH|g" \
        -e "s|Exec=kitty|Exec=$EXEC_PATH|g" \
        "$desktop_target"
    then
        tlog_error "install:$CANONICAL_ID" "Failed to update desktop file: $desktop_target"

        exit 9
    fi
done

set_registry "INSTALL_PATH" "$KITTY_INSTALL_DIR" || exit 13
save_registry "$CANONICAL_ID" || exit 13

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"

add_system_toolkit_message "$CANONICAL_ID"
