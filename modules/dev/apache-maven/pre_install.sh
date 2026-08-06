#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/install-target.sh"
source "$LIB_INSTALLER/state.sh"

__resolve_download_url() {
    local canonical_id="$1"
    local download_page="$2"
    local tag="pre-install:$canonical_id"
    local page
    local url

    if ! page="$(curl -fsSL "$download_page")"; then
        tlog_error "$tag" "Failed to inspect the Apache Maven download page"

        return 2
    fi

    if ! url="$(
        grep -oE \
            'https://[^"[:space:]]+apache-maven-[0-9.]+-bin[.]tar[.]gz' \
            <<<"$page"
    )" || [[ -z "$url" ]]; then
        tlog_error "$tag" "No Apache Maven binary archive was found"

        return 2
    fi

    url="${url%%$'\n'*}"

    printf '%s\n' "$url"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local download_page="https://maven.apache.org/download.cgi"
    local archive_file
    local install_path
    local tag="pre-install:$canonical_id"
    local url

    install_path="$(resolve_install_target "$canonical_id" "$raw_install_path")" || return $?

    if ! archive_file="$(mktemp --suffix=.tar.gz)"; then
        tlog_error "$tag" "Failed to create a temporary archive"

        return 2
    fi

    if ! url="$(__resolve_download_url "$canonical_id" "$download_page")"; then
        rm -f -- "$archive_file"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$archive_file"; then
        tlog_error "$tag" "Failed to download the Apache Maven archive"
        rm -f -- "$archive_file"

        return 3
    fi

    if ! set_state "ARCHIVE_FILE" "$archive_file" ||
        ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to save installation state"
        rm -f -- "$archive_file"

        return 4
    fi

    tlog_info "$tag" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}"
