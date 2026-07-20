#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DEB_FILE="$(get_state "DEB_FILE")" || exit 1

case "$DEB_FILE" in
    *.deb)
        ;;

    *)
        log_error "[$CANONICAL_ID] Expected a .deb file, got: $DEB_FILE"

        exit 2
        ;;
esac

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$CANONICAL_ID] Package file not found: $DEB_FILE"

    exit 2
fi

log_info "[$CANONICAL_ID] Installing package: $DEB_FILE"

if ! apt_install "$DEB_FILE"; then
    log_error "[$CANONICAL_ID] Package installation failed"

    exit 3
fi

log_info "[$CANONICAL_ID] Package installed successfully"

exit 0
