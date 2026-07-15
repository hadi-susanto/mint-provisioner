#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"
source "$LIB_DIR/messages.sh"

load_states "$CANONICAL_ID" || log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

DOUBLE_COMMANDER_PACKAGE="$(get_state "DOUBLE_COMMANDER_PACKAGE" "doublecmd-gtk")"

log_info "[$CANONICAL_ID] Installing using $DOUBLE_COMMANDER_PACKAGE package"

apt_install "$DOUBLE_COMMANDER_PACKAGE"
