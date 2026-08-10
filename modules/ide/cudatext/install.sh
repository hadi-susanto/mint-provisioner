#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DEB_FILE="$(get_state "DEB_FILE")" || exit 1

case "$DEB_FILE" in
    *.deb)
        ;;

    *)
        tlog_error "$CANONICAL_ID" "Expected a .deb file, got: %s" "$DEB_FILE"

        exit 2
        ;;
esac

if [[ ! -f "$DEB_FILE" ]]; then
    tlog_error "$CANONICAL_ID" "Package file not found: %s" "$DEB_FILE"

    exit 2
fi

tlog_info "$CANONICAL_ID" "Installing package: %s" "$DEB_FILE"

if ! apt_install "$CANONICAL_ID" "$DEB_FILE"; then
    tlog_error "$CANONICAL_ID" "Package installation failed"

    exit 3
fi

tlog_info "$CANONICAL_ID" "Package installed successfully"

exit 0
