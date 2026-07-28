#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! deb_file="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -z "${HTTPTOOLKIT_REGEX:-}" ]]; then
    HTTPTOOLKIT_REGEX='HttpToolkit-.*-x64\.deb$'
fi

log_info \
    "[$CANONICAL_ID] Finding GitHub latest release using regex: $HTTPTOOLKIT_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        httptoolkit \
        httptoolkit-desktop \
        "$HTTPTOOLKIT_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    rm -f "$deb_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$deb_file"; then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$deb_file"

    exit 3
fi

if ! set_state "DEB_FILE" "$deb_file"; then
    log_error "[$CANONICAL_ID] Failed to store installation state"
    rm -f "$deb_file"

    exit 4
fi

if ! save_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to save installation state"
    rm -f "$deb_file"

    exit 5
fi

log_info "[$CANONICAL_ID] Download completed successfully"
