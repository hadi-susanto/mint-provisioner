#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Brave Origin installation state was not found"

    exit 1
fi

package="$(get_state "BRAVE_ORIGIN_PACKAGE")" || exit 2

if [[ -z "$package" ]]; then
    log_error "BRAVE_ORIGIN_PACKAGE must not be empty"

    exit 3
fi

apt_install "$package"
