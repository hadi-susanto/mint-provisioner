#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_file_path="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -z "${MONGODB_COMPASS_REGEX:-}" ]]; then
    MONGODB_COMPASS_REGEX='mongodb-compass_.*_amd64\.deb$'
fi

log_info \
    "[$CANONICAL_ID] Finding GitHub latest release using regex: $MONGODB_COMPASS_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        mongodb-js \
        compass \
        "$MONGODB_COMPASS_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    rm -f "$download_file_path"

    exit 2
fi

if ! download_file \
    "$CANONICAL_ID" \
    "$url" \
    "$download_file_path"
then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$download_file_path"

    exit 3
fi

set_state "DEB_FILE" "$download_file_path"

if ! save_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to save installation state"
    rm -f "$download_file_path"

    exit 4
fi

log_info "[$CANONICAL_ID] Download completed successfully"
