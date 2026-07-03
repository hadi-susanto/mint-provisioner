#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"

MODULE="bottom"
STATE_FILE="$STATE_DIR/bottom.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${BOTTOM_REGEX:-}" ]]; then
    BOTTOM_REGEX="bottom-musl_.*_amd64\\.deb"
fi

log_info "[$MODULE] Finding github latest release using regex: $BOTTOM_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        clementtsang \
        bottom \
        "$BOTTOM_REGEX"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    log_error "[$MODULE] No release asset matched regex: $BOTTOM_REGEX"
    log_error "[$MODULE] This may indicate that bottom may cease to exists or filename changed"
    log_error "[$MODULE] Please check https://github.com/ClementTsang/bottom/releases"
    log_error "[$MODULE] Alternatively, set BOTTOM_REGEX to manually select an asset"

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
