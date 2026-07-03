#!/usr/bin/env bash

source "$LIB_DIR/installer_external.sh"

MODULE="procs"
STATE_FILE="$STATE_DIR/procs.path"

if ! download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -z "${PROCS_REGEX:-}" ]]; then
    PROCS_REGEX='procs-.*-x86_64-linux\.zip$'
fi

log_info "[$MODULE] Finding github latest release using regex: $PROCS_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        dalance \
        procs \
        "$PROCS_REGEX"
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
