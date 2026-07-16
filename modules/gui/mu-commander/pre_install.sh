#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -z "${MUCOMMANDER_REGEX:-}" ]]; then
    MUCOMMANDER_REGEX="mucommander_.*_x86_64\\.deb"
fi

log_info "[$CANONICAL_ID] Finding github latest release using regex: $MUCOMMANDER_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        mucommander \
        mucommander \
        "$MUCOMMANDER_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    log_error "[$CANONICAL_ID] No release asset matched regex: $MUCOMMANDER_REGEX"
    log_error "[$CANONICAL_ID] This may indicate that muCommander may cease to exists or filename changed"
    log_error "[$CANONICAL_ID] Please check https://github.com/mucommander/mucommander/releases"
    log_error "[$CANONICAL_ID] Alternatively, set MUCOMMANDER_REGEX to manually select an asset"

    rm -f "$download_temp_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_temp_file"; then
    log_error "[$CANONICAL_ID] Download failed"

    rm -f "$download_temp_file"

    exit 3
fi

set_state "DEB_FILE" "$download_temp_file"
save_states "$CANONICAL_ID" || exit 4

log_info "[$CANONICAL_ID] Download completed successfully"
