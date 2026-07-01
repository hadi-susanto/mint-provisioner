#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${MODULES_DIR}/double-commander/helper.sh"

VARIANT=$(double_commander_gui)

log_info "[double-commander] Installing double commander with GUI: $VARIANT"

apt_install "$VARIANT"
