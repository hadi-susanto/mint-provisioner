#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" ||
    log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

package="$(get_state "MICROSOFT_EDGE_PACKAGE" "microsoft-edge-stable")"

apt_install "$package"
