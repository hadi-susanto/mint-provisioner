#!/usr/bin/env bash

#
# Pre-install phase for oh-my-posh.
#

source "$LIB_DIR/installer_external.sh"

MODULE="oh-my-posh"
STATE_FILE_BINARY="$STATE_DIR/oh-my-posh-binary.path"
STATE_FILE_THEMES="$STATE_DIR/oh-my-posh-themes.path"

if [[ -z "${OH_MY_POSH_SUFFIX:-}" ]]; then
    OH_MY_POSH_SUFFIX="linux-amd64"
fi

log_info "[$MODULE] Downloading oh-my-post lastest binary with suffix: $OH_MY_POSH_SUFFIX"

binary_url="https://cdn.ohmyposh.dev/releases/latest/posh-$OH_MY_POSH_SUFFIX"
themes_url="https://cdn.ohmyposh.dev/releases/latest/themes.zip"

log_info "[$MODULE] Creating temporary download files"

if ! binary_download_file="$(mktemp)"; then
    log_error "[$MODULE] Failed to create temporary file for binary"

    exit 1
fi

if ! themes_download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$MODULE] Failed to create temporary file for themes"
    rm -f "$binary_download_file"

    exit 1
fi

log_info "[$MODULE] Creating state files"
echo "$binary_download_file" > "$STATE_FILE_BINARY"
echo "$themes_download_file" > "$STATE_FILE_THEMES"

log_info "[$MODULE] Downloading binary from $binary_url"
if ! download_from_url "$MODULE" "$binary_url" "$binary_download_file"; then
    log_error "[$MODULE] Binary download failed"
    rm -f "$STATE_FILE_BINARY" "$STATE_FILE_THEMES"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 2
fi

log_info "[$MODULE] Downloading themes from $themes_url"
if ! download_from_url "$MODULE" "$themes_url" "$themes_download_file"; then
    log_error "[$MODULE] Themes download failed"
    rm -f "$STATE_FILE_BINARY" "$STATE_FILE_THEMES"
    rm -f "$binary_download_file" "$themes_download_file"

    exit 3
fi

log_info "[$MODULE] Download completed successfully"
