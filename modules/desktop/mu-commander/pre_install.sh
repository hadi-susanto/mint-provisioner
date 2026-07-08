#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"

MODULE="mu-commander"
STATE_FILE="$STATE_DIR/mu-commander.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${MUCOMMANDER_REGEX:-}" ]]; then
    MUCOMMANDER_REGEX="mucommander_.*_x86_64\\.deb"
fi

log_info "[$MODULE] Finding github latest release using regex: $MUCOMMANDER_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        mucommander \
        mucommander \
        "$MUCOMMANDER_REGEX"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    log_error "[$MODULE] No release asset matched regex: $MUCOMMANDER_REGEX"
    log_error "[$MODULE] This may indicate that muCommander may cease to exists or filename changed"
    log_error "[$MODULE] Please check https://github.com/mucommander/mucommander/releases"
    log_error "[$MODULE] Alternatively, set MUCOMMANDER_REGEX to manually select an asset"

    rm -f "$download_temp_file"

    exit 2
fi

if ! download_file "$MODULE" "$url" "$download_temp_file"; then
    log_error "[$MODULE] Download failed"

    rm -f "$download_temp_file"

    exit 3
fi

log_info "[$MODULE] Creating state file: $STATE_FILE"

if ! printf '%s\n' "$download_temp_file" > "$STATE_FILE"; then
    log_error "[$MODULE] Failed to create state file"

    rm -f "$download_temp_file"

    exit 4
fi

log_info "[$MODULE] Download completed successfully"
