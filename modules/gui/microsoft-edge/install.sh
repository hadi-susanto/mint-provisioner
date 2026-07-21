#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Microsoft Edge installation state was not found"

    exit 1
fi

package="$(get_state "MICROSOFT_EDGE_PACKAGE")" || exit 2

if [[ -z "$package" ]]; then
    log_error "MICROSOFT_EDGE_PACKAGE must not be empty"

    exit 3
fi

apt_install "$package"
