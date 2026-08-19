#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

__resolve_download_url() {
    local canonical_id="$1"
    local download_page="https://maven.apache.org/download.cgi"
    local tag="pre-install:$canonical_id"
    local page
    local url

    if ! page="$(curl -fsSL "$download_page")"; then
        tlog_error "$tag" "Failed to inspect the Apache Maven download page"

        return 1
    fi

    if ! url="$(grep -oE 'https://[^"[:space:]]+apache-maven-[0-9.]+-bin[.]tar[.]gz' <<<"$page")"; then
        tlog_error "$tag" "Failed to extract the Apache Maven binary archive URL"

        return 1
    fi

    if [[ -z "$url" ]]; then
        tlog_error "$tag" "No Apache Maven binary archive was found"

        return 1
    fi

    url="${url%%$'\n'*}"

    printf '%s\n' "$url"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local url

    valid_install_target "$canonical_id" "$raw_install_path" "APACHE_MAVEN_INSTALL_DIR" || return $?
    url="$(__resolve_download_url "$canonical_id")" || return $?
    stateful_download "$canonical_id" "ARCHIVE_FILE" "$url" ".tar.gz"
}

main "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}"
