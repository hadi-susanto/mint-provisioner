#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/external.sh"
source "${LIB_INSTALLER}/state.sh"

tlog_info "pre-install:$CANONICAL_ID" "Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file"

    exit 3
fi

if [[ -z "${FMAN_REGEX:-}" ]]; then
    FMAN_REGEX="fman-.*-ubuntu-x64\\.deb$"
fi

tlog_info "pre-install:$CANONICAL_ID" "Finding GitHub latest release using regex: $FMAN_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        mherrmann \
        fman \
        "$FMAN_REGEX"
)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to resolve latest release"
    tlog_error "pre-install:$CANONICAL_ID" "No release asset matched regex: $FMAN_REGEX"
    tlog_error "pre-install:$CANONICAL_ID" "The fman release filename may have changed"
    tlog_error "pre-install:$CANONICAL_ID" "Please check https://github.com/mherrmann/fman/releases"
    tlog_error "pre-install:$CANONICAL_ID" "Alternatively, set FMAN_REGEX to manually select an asset"

    rm -f "$download_temp_file"

    exit 4
fi

if ! download_file \
    "$CANONICAL_ID" \
    "$url" \
    "$download_temp_file"
then
    tlog_error "pre-install:$CANONICAL_ID" "Download failed"

    rm -f "$download_temp_file"

    exit 5
fi

set_state "DEB_FILE" "$download_temp_file"

if ! save_states "$CANONICAL_ID"; then
    rm -f "$download_temp_file"

    exit 6
fi

tlog_info "pre-install:$CANONICAL_ID" "Download completed successfully"
