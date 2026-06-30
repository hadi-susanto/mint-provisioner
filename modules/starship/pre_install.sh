#!/usr/bin/env bash

#
# Pre-install phase for starship.
#

source "$LIB_DIR/installer_external.sh"

MODULE="starship"
STATE_FILE="$STATE_DIR/starship.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${STARSHIP_REGEX:-}" ]]; then
    STARSHIP_REGEX="starship-x86_64-unknown-linux-musl\\.tar\\.gz$"
fi

log_info "[$MODULE] Finding github latest release using regex: $STARSHIP_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        starship \
        starship \
        "$STARSHIP_REGEX"
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
