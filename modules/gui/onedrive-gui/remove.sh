#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"
source "$LIB_REMOVER/home.sh"
source "$LIB_WORKFLOW/pipx-package.sh"

remove_symlink "$CANONICAL_ID" "onedrive-gui" || exit $?
remove_desktop_entry "$CANONICAL_ID" "onedrive-gui" || exit $?

# INSTALL_PATH is a pipx home shared with other modules, so only this package is uninstalled.
if load_registry "$CANONICAL_ID" silent && install_path="$(get_registry "INSTALL_PATH")"; then
    pipx_package_uninstall "$CANONICAL_ID" "$install_path" "onedrive-gui" || exit $?
fi

purge_home_paths "$CANONICAL_ID" "onedrive-gui" "autostart/OneDriveGUI.desktop"
