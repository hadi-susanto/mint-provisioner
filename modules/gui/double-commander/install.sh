#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${LIB_DIR}/installer_apt.sh"
source "${SCRIPT_DIR}/helper.sh"

VARIANT=$(double_commander_gui)

log_info "[double-commander] Installing double commander with GUI: $VARIANT"

apt_install "$VARIANT"
