#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

tlog_info "pre-install:$CANONICAL_ID" "Creating temporary download file"

if ! download_file="$(mktemp --suffix=.txz)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file"

    exit 1
fi

if [[ -z "${KITTY_REGEX:-}" ]]; then
    KITTY_REGEX="x86_64\\.txz$"
fi

tlog_info "pre-install:$CANONICAL_ID" "Finding github latest release using regex: $KITTY_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        kovidgoyal \
        kitty \
        "$KITTY_REGEX"
)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to resolve latest release"
    rm -f "$download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
    tlog_error "pre-install:$CANONICAL_ID" "Download failed"
    rm -f "$download_file"

    exit 3
fi

set_state "ARCHIVE_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 4

tlog_info "pre-install:$CANONICAL_ID" "Download completed successfully"
