#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

__install_desktop_entry() {
    local canonical_id="$1"
    local install_path="$2"
    local executable="$install_path/app/Postman"
    local icon="$install_path/app/resources/app/assets/icon.png"
    local application_dir="/usr/share/applications"
    local desktop_file="$application_dir/postman.desktop"
    local tag="install:$canonical_id"

    if ! sudo mkdir -p "$application_dir"; then
        tlog_error "$tag" "Failed to create desktop application directory"

        return 1
    fi

    if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Postman
Comment=Build, test, and document APIs
Exec=$executable %U
TryExec=$executable
Icon=$icon
Terminal=false
Categories=Development;
Keywords=API;HTTP;REST;GraphQL;Testing;
StartupWMClass=Postman
EOF
    then
        tlog_error "$tag" "Failed to install desktop file: %s" "$desktop_file"

        return 1
    fi

    if ! sudo chmod 0644 "$desktop_file"; then
        tlog_error "$tag" "Failed to set desktop file permissions: %s" "$desktop_file"

        return 1
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
    local install_path
    local tag="install:$canonical_id"

    install_path="$(expand_path "$raw_install_path")" || return $?
    stateful_extract_install \
        "$canonical_id" \
        "ARCHIVE_FILE" \
        "tar" \
        "$install_path" \
        "app/Postman" \
        "postman" \
        -- \
        "--strip-components=1" || return $?
    __install_desktop_entry "$canonical_id" "$install_path"
}

main "$CANONICAL_ID" "${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"
