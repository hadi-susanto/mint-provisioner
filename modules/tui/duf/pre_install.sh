#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file"

    exit 1
fi

if [[ -z "${DUF_REGEX:-}" ]]; then
    DUF_REGEX='duf_.*_linux_x86_64\.tar\.gz$'
fi

tlog_info "pre-install:$CANONICAL_ID" "Finding github latest release using regex: $DUF_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        muesli \
        duf \
        "$DUF_REGEX"
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
