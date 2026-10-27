#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_ONEDRIVE_GUI_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_ONEDRIVE_GUI_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# onedrive_gui_install_requirements <canonical_id> <install_path>
#
# Installs or upgrades the OneDriveGUI Python requirements into the virtual
# environment at <install_path>/.venv. Used by install and upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging.
#   install_path - OneDriveGUI clone directory.
#
# Return:
#   1 - pip failed to install the requirements.
#
onedrive_gui_install_requirements() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="venv:$canonical_id"

    tlog_info "$tag" "Installing OneDriveGUI Python requirements"
    if ! "$install_path/.venv/bin/python" -m pip install --upgrade -r "$install_path/requirements.txt"; then
        tlog_error "$tag" "pip failed to install OneDriveGUI requirements"

        return 1
    fi
}
