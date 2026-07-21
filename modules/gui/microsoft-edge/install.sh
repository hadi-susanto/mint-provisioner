#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/messages.sh"
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

if ! apt_install "$package"; then
    add_message "$CANONICAL_ID" "warn" "Installation failed: $package"

    exit 1
fi

add_message "$CANONICAL_ID" "info" "Installation success: $package"
