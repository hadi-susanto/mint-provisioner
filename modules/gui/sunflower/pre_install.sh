#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

tlog_info "pre-install:$CANONICAL_ID" "Creating temporary download file"

if ! download_temp_file="$(mktemp --suffix=.deb)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file"

    exit 1
fi

if [[ -z "${SUNFLOWER_REGEX:-}" ]]; then
    SUNFLOWER_REGEX="sunflower-.*\\.all\\.deb"
fi

tlog_info "pre-install:$CANONICAL_ID" "Finding github latest release using regex: $SUNFLOWER_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        MeanEYE \
        Sunflower \
        "$SUNFLOWER_REGEX"
)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to resolve latest release"
    tlog_error "pre-install:$CANONICAL_ID" "No release asset matched regex: $SUNFLOWER_REGEX"
    tlog_error "pre-install:$CANONICAL_ID" "This may indicate that Sunflower may cease to exists or filename changed"
    tlog_error "pre-install:$CANONICAL_ID" "Please check https://github.com/MeanEYE/Sunflower/releases"
    tlog_error "pre-install:$CANONICAL_ID" "Alternatively, set SUNFLOWER_REGEX to manually select an asset"

    rm -f "$download_temp_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_temp_file"; then
    tlog_error "pre-install:$CANONICAL_ID" "Download failed"

    rm -f "$download_temp_file"

    exit 3
fi

set_state "DEB_FILE" "$download_temp_file"
save_states "$CANONICAL_ID" || exit 4

tlog_info "pre-install:$CANONICAL_ID" "Download completed successfully"
