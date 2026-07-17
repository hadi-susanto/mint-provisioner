#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -z "${BAT_REGEX:-}" ]]; then
    BAT_REGEX='bat_.*_amd64\.deb$'
fi

log_info "[$CANONICAL_ID] Finding github latest release using regex: $BAT_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        sharkdp \
        bat \
        "$BAT_REGEX"
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

set_state "DEB_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 4

log_info "[$CANONICAL_ID] Download completed successfully"
