#!/usr/bin/env bash

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

DOWNLOAD_URL="https://maven.apache.org/download.cgi"

log_info "[$CANONICAL_ID] Scraping $DOWNLOAD_URL for latest release"

# Scrape the page for the first binary tar.gz link
# We look for links matching apache-maven-*-bin.tar.gz
if ! url=$(curl -fsSL "$DOWNLOAD_URL" | grep -oP 'https://[^\s"]+apache-maven-[0-9.]+-bin\.tar\.gz' | head -n 1); then
    log_error "[$CANONICAL_ID] Failed to find download URL on $DOWNLOAD_URL"
    rm -f "$download_file"

    exit 2
fi

log_info "[$CANONICAL_ID] Found download URL: $url"

if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
    log_error "[$CANONICAL_ID] Failed to download $url"
    rm -f "$download_file"

    exit 3
fi

set_state "ARCHIVE_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 4
