#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

install_path="$(expand_path "${KITTY_INSTALL_DIR:-$INSTALL_DIR/kitty}")" || return $?
stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "txz" \
    "$install_path" \
    "bin/kitty" "kitty" \
    "bin/kitten" "kitten" || exit $?

tag="install:$CANONICAL_ID"
install_open_handler="${KITTY_INSTALL_OPEN_HANDLER:-false}"
application_dir="/usr/share/applications"
desktop_files=("kitty.desktop")

tlog_info "$tag" "Installing desktop files"
if [[ "$install_open_handler" == "true" ]]; then
    tlog_info "$tag" "Installing kitty-open.desktop file"
    desktop_files+=("kitty-open.desktop")
else
    tlog_info "$tag" "Skipping kitty-open.desktop file installation, to install please pass KITTY_INSTALL_OPEN_HANDLER=true"
fi

# Update the paths to the kitty and its icon in the kitty desktop file(s)
icon_path="$install_path/share/icons/hicolor/256x256/apps/kitty.png"
exec_path="$install_path/bin/kitty"

if [[ ! -f "$icon_path" ]]; then
    tlog_error "$tag" "Kitty icon not found: $icon_path"

    exit 1
fi

for desktop_file in "${desktop_files[@]}"; do
    desktop_source="$install_path/share/applications/$desktop_file"
    desktop_target="$application_dir/$desktop_file"

    if [[ ! -f "$desktop_source" ]]; then
        tlog_error "$tag" "Desktop file not found: $desktop_source"

        exit 1
    fi

    if ! sudo install -Dm0644 "$desktop_source" "$desktop_target"; then
        tlog_error "$tag" "Failed to install desktop file: $desktop_target"

        exit 1
    fi

    tlog_info "$tag" "Updating paths in $desktop_target"

    if ! sudo sed -i \
        -e "s|Icon=kitty|Icon=$icon_path|g" \
        -e "s|Exec=kitty|Exec=$exec_path|g" \
        "$desktop_target"
    then
        tlog_error "$tag" "Failed to update desktop file: $desktop_target"

        exit 1
    fi
done

add_system_toolkit_message "$CANONICAL_ID"
