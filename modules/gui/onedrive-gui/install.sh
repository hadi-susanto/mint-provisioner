#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/desktop-integration.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/state.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_WORKFLOW}/pipx-package.sh"
source "${LIB_WORKFLOW}/version-registry.sh"

__ensure_dependencies() {
    local tag="dependency:$CANONICAL_ID"
    local -a packages=(pipx python3-venv libxcb-cursor0)

    if ! apt_install "$CANONICAL_ID" "${packages[@]}"; then
        tlog_error "$tag" "Failed to install dependencies: %s" "${packages[*]}"

        return 1
    fi

    if ! command -v pipx >/dev/null 2>&1; then
        tlog_error "$tag" "pipx is not available after installing its package"

        return 1
    fi
}

##
# __package_icon <install_path>
#
# Locates the application icon shipped inside the installed onedrive_gui package.
#
# Output:
#   Prints the icon path.
#
# Return:
#   1 - The package could not be located in the pipx venv.
#
__package_icon() {
    local install_path="$1"
    local python="$install_path/venvs/onedrive-gui/bin/python"
    local package_dir

    if ! package_dir="$("$python" -c 'import importlib.util as u; print(u.find_spec("onedrive_gui").submodule_search_locations[0])')"; then
        tlog_error "desktop:$CANONICAL_ID" "Failed to locate the onedrive_gui package in %s" "$python"

        return 1
    fi

    printf '%s\n' "$package_dir/resources/images/OneDriveGUI.png"
}

main() {
    local raw_install_path="$1"
    local install_path
    local version
    local icon_file

    install_path="$(expand_path "$raw_install_path")" || return $?
    load_states "$CANONICAL_ID" || return $?
    version="$(get_state "VERSION")" || return $?
    __ensure_dependencies || return $?
    pipx_package_install "$CANONICAL_ID" "$install_path" "onedrive-gui" \
        "onedrive-gui @ git+https://github.com/bpozdena/OneDriveGUI.git@$version" || return $?
    symlink_binary "$CANONICAL_ID" "$(pipx_package_binary "$install_path" "onedrive-gui")" || return $?
    icon_file="$(__package_icon "$install_path")" || return $?
    install_desktop_entry "$CANONICAL_ID" "onedrive-gui" "OneDriveGUI" "onedrive-gui" \
        --try-exec "onedrive-gui" \
        --generic-name "OneDrive Sync" \
        --comment "A simple GUI for OneDrive Linux client" \
        --icon-file "$icon_file" \
        --icon-size "64x64" \
        --categories "Network;FileTransfer;Qt;" \
        --keywords "OneDrive;Sync;Cloud;Microsoft;" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$CANONICAL_ID" || return $?
    record_version_registry "$CANONICAL_ID"
}

main "${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
