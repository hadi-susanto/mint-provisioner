#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 3
fi

if [[ -z "${FMAN_REGEX:-}" ]]; then
    FMAN_REGEX="fman-.*-ubuntu-x64\\.deb$"
fi

log_info "[$CANONICAL_ID] Finding GitHub latest release using regex: $FMAN_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        mherrmann \
        fman \
        "$FMAN_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    log_error "[$CANONICAL_ID] No release asset matched regex: $FMAN_REGEX"
    log_error "[$CANONICAL_ID] The fman release filename may have changed"
    log_error "[$CANONICAL_ID] Please check https://github.com/mherrmann/fman/releases"
    log_error "[$CANONICAL_ID] Alternatively, set FMAN_REGEX to manually select an asset"

    rm -f "$download_temp_file"

    exit 4
fi

if ! download_file \
    "$CANONICAL_ID" \
    "$url" \
    "$download_temp_file"
then
    log_error "[$CANONICAL_ID] Download failed"

    rm -f "$download_temp_file"

    exit 5
fi

set_state "DEB_FILE" "$download_temp_file"

if ! save_states "$CANONICAL_ID"; then
    rm -f "$download_temp_file"

    exit 6
fi

log_info "[$CANONICAL_ID] Download completed successfully"
