#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -r DOWNLOAD_URL="https://deadbeef.sourceforge.io/download.html"
install_dir="${DEADBEEF_INSTALL_DIR:-$INSTALL_DIR/deadbeef}"

valid_install_target "$CANONICAL_ID" "$install_dir" "DEADBEEF_INSTALL_DIR" || exit $?

tlog_info "pre-install:$CANONICAL_ID" "Scraping $DOWNLOAD_URL for latest release"
if ! url=$(curl -fsSL "$DOWNLOAD_URL" | grep -oP 'https://[^\s"]+deadbeef-static_[^"]+_x86_64\.tar\.bz2/download' | head -n 1) || [[ -z "$url" ]]; then
    tlog_error "pre-install:$CANONICAL_ID" "Failed to find download URL on $DOWNLOAD_URL"

    exit 1
fi

tlog_info "pre-install:$CANONICAL_ID" "Found download URL: $url"
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.bz2"
