#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

if [[ "${MKVTOOLNIX_GUI_ENABLED:-false}" == "true" ]]; then
    log_info "[mkvtoolnix] Installing mkvtoolnix-gui because MKVTOOLNIX_GUI_ENABLED is true"

    apt_install mkvtoolnix-gui
else
    log_info "[mkvtoolnix] Installing mkvtoolnix, only CLI tools."
    log_info "[mkvtoolnix] To install GUI part please re-run with MKVTOOLNIX_GUI_ENABLED=true"

    apt_install mkvtoolnix
fi
