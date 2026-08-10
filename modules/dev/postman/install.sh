#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"

__install_desktop_entry() {
    local canonical_id="$1"
    local executable="$2"
    local icon="$3"
    local launcher="$4"
    local application_dir="/usr/share/applications"
    local desktop_file="$application_dir/postman.desktop"
    local tag="install:$canonical_id"

    if ! sudo mkdir -p "$application_dir"; then
        tlog_error "$tag" "Failed to create desktop application directory"

        return 9
    fi

    if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Postman
Comment=Build, test, and document APIs
Exec=$launcher %U
TryExec=$executable
Icon=$icon
Terminal=false
Categories=Development;
Keywords=API;HTTP;REST;GraphQL;Testing;
StartupWMClass=Postman
EOF
    then
        tlog_error "$tag" "Failed to install desktop file: %s" "$desktop_file"

        return 10
    fi

    if ! sudo chmod 0644 "$desktop_file"; then
        tlog_error "$tag" "Failed to set desktop file permissions: %s" "$desktop_file"

        return 11
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        if ! sudo update-desktop-database "$application_dir"; then
            tlog_warn "$tag" "Failed to refresh the desktop application database"
        fi
    fi
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local executable
    local icon
    local install_path
    local launcher
    local tag="install:$canonical_id"

    load_states "$canonical_id" || return 1
    archive_file="$(get_state "ARCHIVE_FILE")" || return 1

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Archive file not found: %s" "$archive_file"

        return 2
    fi

    install_path="$(expand_path "$raw_install_path")" || return $?
    executable="$install_path/app/Postman"
    icon="$install_path/app/resources/app/assets/icon.png"
    launcher="$(symlink_location)/postman"

    if ! mkdir -p -- "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 3
    fi

    if ! tar --overwrite -xzf "$archive_file" -C "$install_path" --strip-components=1; then
        tlog_error "$tag" "Failed to extract Postman into: %s" "$install_path"

        return 4
    fi

    if ! chmod 0755 "$executable"; then
        tlog_error "$tag" "Failed to make Postman executable: %s" "$executable"

        return 5
    fi

    if [[ ! -x "$executable" || ! -f "$icon" ]]; then
        tlog_error "$tag" "Postman archive is missing its executable or icon"

        return 6
    fi

    symlink_binary "$canonical_id" "$executable" postman || return 8
    __install_desktop_entry \
        "$canonical_id" "$executable" "$icon" "$launcher" || return $?

    set_registry "INSTALL_PATH" "$install_path" || return 12
    save_registry "$canonical_id" || return 12

    tlog_info "$tag" "Postman installed successfully"
}

main "$CANONICAL_ID" "${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"
