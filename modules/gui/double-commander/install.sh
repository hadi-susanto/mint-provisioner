#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"
source "$LIB_DIR/messages.sh"

if ! load_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Double Commander installation state was not found"

    exit 1
fi

DOUBLE_COMMANDER_PACKAGE="$(get_state "DOUBLE_COMMANDER_PACKAGE")" || exit 2

if [[ -z "$DOUBLE_COMMANDER_PACKAGE" ]]; then
    log_error "DOUBLE_COMMANDER_PACKAGE must not be empty"

    exit 3
fi

log_info "[$CANONICAL_ID] Installing using $DOUBLE_COMMANDER_PACKAGE package"

apt_install "$DOUBLE_COMMANDER_PACKAGE"
