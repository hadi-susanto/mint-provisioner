#!/usr/bin/env bash

#
# Pre-install phase for kitty.
#

source "$LIB_DIR/installer_external.sh"

MODULE="kitty"
STATE_FILE="$STATE_DIR/kitty.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.txz)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${KITTY_REGEX:-}" ]]; then
    KITTY_REGEX="x86_64\\.txz$"
fi

log_info "[$MODULE] Finding github latest release using regex: $KITTY_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        kovidgoyal \
        kitty \
        "$KITTY_REGEX"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    rm -f "$download_file"

    exit 2
fi

log_info "[$MODULE] Creating state file: $STATE_FILE"

if ! printf '%s\n' "$download_file" > "$STATE_FILE"; then
    log_error "[$MODULE] Failed to create state file"
    rm -f "$download_file"

    exit 3
fi

if ! download_file "$MODULE" "$url" "$download_file"; then
    log_error "[$MODULE] Download failed"
    rm -f "$STATE_FILE"
    rm -f "$download_file"

    exit 4
fi

log_info "[$MODULE] Download completed successfully"
