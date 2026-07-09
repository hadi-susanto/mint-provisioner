#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"

MODULE="sunflower"
STATE_FILE="$STATE_DIR/sunflower.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${SUNFLOWER_REGEX:-}" ]]; then
    SUNFLOWER_REGEX="sunflower-.*\\.all\\.deb"
fi

log_info "[$MODULE] Finding github latest release using regex: $SUNFLOWER_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        MeanEYE \
        Sunflower \
        "$SUNFLOWER_REGEX"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    log_error "[$MODULE] No release asset matched regex: $SUNFLOWER_REGEX"
    log_error "[$MODULE] This may indicate that Sunflower may cease to exists or filename changed"
    log_error "[$MODULE] Please check https://github.com/MeanEYE/Sunflower/releases"
    log_error "[$MODULE] Alternatively, set $SUNFLOWER_REGEX to manually select an asset"

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
