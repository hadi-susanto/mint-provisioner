#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
archive_file="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$archive_file" ]]; then
    log_error "[$CANONICAL_ID] Archive file not found: $archive_file"

    exit 2
fi

postman_install_dir="${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"
exec_path="${postman_install_dir}/app/Postman"
icon_path="${postman_install_dir}/app/resources/app/assets/icon.png"
application_dir="/usr/share/applications"
desktop_file="${application_dir}/postman.desktop"
launcher_path="$(symlink_location)/postman"
declare -a privilege=()

if ! can_write "$postman_install_dir"; then
    privilege=(sudo)
fi

log_info "[$CANONICAL_ID] Extracting Postman to $postman_install_dir"

if ! "${privilege[@]}" mkdir -p "$postman_install_dir"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $postman_install_dir"

    exit 3
fi

if ! "${privilege[@]}" tar \
    --overwrite \
    -xzf "$archive_file" \
    -C "$postman_install_dir" \
    --strip-components=1
then
    log_error "[$CANONICAL_ID] Failed to extract Postman"

    exit 4
fi

if ! "${privilege[@]}" chmod 0755 "$exec_path"; then
    log_error "[$CANONICAL_ID] Failed to make Postman executable: $exec_path"

    exit 5
fi

if [[ ! -x "$exec_path" ]]; then
    log_error "[$CANONICAL_ID] Postman executable not found: $exec_path"

    exit 6
fi

if [[ ! -f "$icon_path" ]]; then
    log_error "[$CANONICAL_ID] Postman application icon not found: $icon_path"

    exit 7
fi

log_info "[$CANONICAL_ID] Creating global Postman command: $launcher_path"

if ! symlink_binary "$CANONICAL_ID" "$exec_path" "postman"; then
    log_error "[$CANONICAL_ID] Failed to create global Postman command"

    exit 8
fi

log_info "[$CANONICAL_ID] Installing desktop file: $desktop_file"

if ! sudo mkdir -p "$application_dir"; then
    log_error "[$CANONICAL_ID] Failed to create desktop application directory: $application_dir"

    exit 9
fi

if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Postman
Comment=Build, test, and document APIs
Exec=$launcher_path %U
TryExec=$launcher_path
Icon=$icon_path
Terminal=false
Categories=Development;
Keywords=API;HTTP;REST;GraphQL;Testing;
StartupWMClass=Postman
EOF
then
    log_error "[$CANONICAL_ID] Failed to install desktop file: $desktop_file"

    exit 10
fi

if ! sudo chmod 0644 "$desktop_file"; then
    log_error "[$CANONICAL_ID] Failed to set desktop file permissions: $desktop_file"

    exit 11
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    if ! sudo update-desktop-database "$application_dir"; then
        log_warn "[$CANONICAL_ID] Failed to refresh the desktop application database"
    fi
fi

log_info "[$CANONICAL_ID] Postman installed successfully"
