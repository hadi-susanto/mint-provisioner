#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" ||
    log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

PGADMIN_PACKAGE="$(
    get_state "PGADMIN_PACKAGE" "pgadmin4-desktop"
)"

log_info "[$CANONICAL_ID] Installing using $PGADMIN_PACKAGE package"

if ! apt_install "$PGADMIN_PACKAGE"; then
    log_error "[$CANONICAL_ID] Package installation failed"

    exit 1
fi

log_info "[$CANONICAL_ID] Package installed successfully"
