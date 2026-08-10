#!/usr/bin/env bash
set -euo pipefail

#
# Pre-install phase for oh-my-posh.
#

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

if [[ -z "${OH_MY_POSH_SUFFIX:-}" ]]; then
    OH_MY_POSH_SUFFIX="linux-amd64"
fi

tlog_info "pre-install:$CANONICAL_ID" "Downloading oh-my-post lastest binary with suffix: $OH_MY_POSH_SUFFIX"

binary_url="https://cdn.ohmyposh.dev/releases/latest/posh-$OH_MY_POSH_SUFFIX"
themes_url="https://cdn.ohmyposh.dev/releases/latest/themes.zip"

tlog_info "pre-install:$CANONICAL_ID" "Creating temporary download files"

if ! binary_download_file="$(mktemp)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file for binary"

    exit 1
fi

if ! themes_download_file="$(mktemp --suffix=.zip)"; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to create temporary file for themes"
    rm -f "$binary_download_file"

    exit 1
fi

if ! download_file "$CANONICAL_ID" "$binary_url" "$binary_download_file"; then
    tlog_error "pre-install:$CANONICAL_ID" "Binary download failed"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$themes_url" "$themes_download_file"; then
    tlog_error "pre-install:$CANONICAL_ID" "Themes download failed"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 3
fi

set_state "BINARY_FILE" "$binary_download_file"
set_state "THEMES_FILE" "$themes_download_file"
save_states "$CANONICAL_ID" || exit 4

tlog_info "pre-install:$CANONICAL_ID" "Download completed successfully"
