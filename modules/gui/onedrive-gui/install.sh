#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/desktop-integration.sh"
source "${LIB_INSTALLER}/git-clone.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/symlink.sh"

declare -r ONEDRIVE_GUI_URL="https://github.com/bpozdena/OneDriveGUI.git"

__ensure_dependencies() {
    local canonical_id="$1"
    local tag="dependency:$canonical_id"

    if ! apt_install "$canonical_id" "python3-venv" "libxcb-cursor0"; then
        tlog_error "$tag" "Failed to install Python venv or Qt runtime dependencies"

        return 1
    fi
}

__create_venv() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="venv:$canonical_id"
    local venv_path="$install_path/.venv"

    tlog_info "$tag" "Creating Python virtual environment: %s" "$venv_path"
    if ! python3 -m venv "$venv_path"; then
        tlog_error "$tag" "Failed to create Python virtual environment: %s" "$venv_path"

        return 1
    fi

    tlog_info "$tag" "Installing OneDriveGUI Python requirements"
    if ! "$venv_path/bin/python" -m pip install --upgrade -r "$install_path/requirements.txt"; then
        tlog_error "$tag" "pip failed to install OneDriveGUI requirements"

        return 1
    fi
}

__install_wrapper() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="wrapper:$canonical_id"
    local wrapper_file="$install_path/onedrivegui"

    if ! install -m 755 "$MP_MODULES/$canonical_id/payload/onedrivegui" "$wrapper_file"; then
        tlog_error "$tag" "Failed to install wrapper to %s" "$wrapper_file"

        return 1
    fi

    symlink_binary "$canonical_id" "$wrapper_file"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path

    install_path="$(expand_path "$raw_install_path")" || return $?
    __ensure_dependencies "$canonical_id" || return $?
    git_clone "$canonical_id" "$ONEDRIVE_GUI_URL" "$install_path" "src/OneDriveGUI.py" || return $?
    __create_venv "$canonical_id" "$install_path" || return $?
    __install_wrapper "$canonical_id" "$install_path" || return $?
    install_desktop_entry "$canonical_id" "onedrive-gui" "OneDriveGUI" "onedrivegui" \
        --try-exec "onedrivegui" \
        --generic-name "OneDrive Sync" \
        --comment "A simple GUI for OneDrive Linux client" \
        --icon-file "$install_path/src/resources/images/OneDriveGUI.png" \
        --icon-size "64x64" \
        --categories "Network;FileTransfer;Qt;" \
        --keywords "OneDrive;Sync;Cloud;Microsoft;" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id"
}

main "$CANONICAL_ID" "${ONEDRIVE_GUI_INSTALL_DIR:-$INSTALL_DIR/onedrive-gui}"
