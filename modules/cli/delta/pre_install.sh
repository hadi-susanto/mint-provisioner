#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -z "${DELTA_REGEX:-}" ]]; then
    DELTA_REGEX='delta-.*-x86_64-unknown-linux-musl\.tar\.gz$'
fi

log_info "[$CANONICAL_ID] Finding github latest release using regex: $DELTA_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        dandavison \
        delta \
        "$DELTA_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"

    rm -f "$download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
    log_error "[$CANONICAL_ID] Download failed"

    rm -f "$download_file"

    exit 3
fi

set_state "ARCHIVE_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 4

log_info "[$CANONICAL_ID] Download completed successfully"
