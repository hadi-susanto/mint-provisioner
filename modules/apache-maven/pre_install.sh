#!/usr/bin/env bash

source "${LIB_DIR}/installer_external.sh"

MODULE="apache-maven"
STATE_FILE="${STATE_DIR}/${MODULE}.path"
DOWNLOAD_URL="https://maven.apache.org/download.cgi"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    exit 1
fi

log_info "[$MODULE] Scraping $DOWNLOAD_URL for latest release"

# Scrape the page for the first binary tar.gz link
# We look for links matching apache-maven-*-bin.tar.gz
if ! url=$(curl -fsSL "$DOWNLOAD_URL" | grep -oP 'https://[^\s"]+apache-maven-[0-9.]+-bin\.tar\.gz' | head -n 1); then
    log_error "[$MODULE] Failed to find download URL on $DOWNLOAD_URL"
    rm -f "$download_file"

    exit 2
fi

log_info "[$MODULE] Found download URL: $url"

printf '%s\n' "$download_file" > "$STATE_FILE"

if ! download_file "$MODULE" "$url" "$download_file"; then
    log_error "[$MODULE] Failed to download $url"
    rm -f "$STATE_FILE" "$download_file"

    exit 3
fi
