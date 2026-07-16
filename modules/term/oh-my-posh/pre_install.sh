#!/usr/bin/env bash

#
# Pre-install phase for oh-my-posh.
#

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

if [[ -z "${OH_MY_POSH_SUFFIX:-}" ]]; then
    OH_MY_POSH_SUFFIX="linux-amd64"
fi

log_info "[$CANONICAL_ID] Downloading oh-my-post lastest binary with suffix: $OH_MY_POSH_SUFFIX"

binary_url="https://cdn.ohmyposh.dev/releases/latest/posh-$OH_MY_POSH_SUFFIX"
themes_url="https://cdn.ohmyposh.dev/releases/latest/themes.zip"

log_info "[$CANONICAL_ID] Creating temporary download files"

if ! binary_download_file="$(mktemp)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file for binary"

    exit 1
fi

if ! themes_download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file for themes"
    rm -f "$binary_download_file"

    exit 1
fi

if ! download_file "$CANONICAL_ID" "$binary_url" "$binary_download_file"; then
    log_error "[$CANONICAL_ID] Binary download failed"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$themes_url" "$themes_download_file"; then
    log_error "[$CANONICAL_ID] Themes download failed"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 3
fi

set_state "BINARY_FILE" "$binary_download_file"
set_state "THEMES_FILE" "$themes_download_file"
save_states "$CANONICAL_ID" || exit 4

log_info "[$CANONICAL_ID] Download completed successfully"
