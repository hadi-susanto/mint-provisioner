#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_error "install:$CANONICAL_ID" "Microsoft Edge installation state was not found"

    exit 1
fi

package="$(get_state "MICROSOFT_EDGE_PACKAGE")" || exit 2

if [[ -z "$package" ]]; then
    tlog_error "install:$CANONICAL_ID" "MICROSOFT_EDGE_PACKAGE must not be empty"

    exit 3
fi

if ! apt_install "$CANONICAL_ID" "$package"; then
    add_message "$CANONICAL_ID" "warn" "Installation failed: $package"

    exit 1
fi

add_message "$CANONICAL_ID" "info" "Installation success: $package"
