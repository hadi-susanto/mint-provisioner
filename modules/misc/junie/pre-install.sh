#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -r JUNIE_UPDATE_INFO_URL="https://raw.githubusercontent.com/jetbrains-junie/junie/main/update-info.jsonl"

__resolve_junie_platform() {
    local canonical_id="$1"
    local tag="platform:$canonical_id"

    case "$(uname -m)" in
        x86_64 | amd64)
            printf '%s\n' "linux-amd64"
            ;;
        aarch64 | arm64)
            printf '%s\n' "linux-aarch64"
            ;;
        *)
            tlog_error "$tag" "Unsupported architecture: %s" "$(uname -m)"

            return 1
            ;;
    esac
}

__resolve_junie_release() {
    local canonical_id="$1"
    local platform="$2"
    local result_name="$3"
    local tag="release:$canonical_id"
    local -n result_ref="$result_name"
    local jsonl
    local entry
    local version
    local url
    local checksum

    tlog_info "$tag" "Resolving latest Junie release for %s" "$platform"
    if ! jsonl="$(curl -fsSL "$JUNIE_UPDATE_INFO_URL")"; then
        tlog_error "$tag" "Failed to download the Junie release index"

        return 1
    fi

    entry="$(
        printf '%s\n' "$jsonl" |
            grep "\"platform\":\"$platform\"" |
            sed 's/.*"version":"\([^"]*\)".*/\1\t&/' |
            LC_ALL=C sort -t. -k1,1n -k2,2n |
            tail -1 |
            cut -f2-
    )"

    if [[ -z "$entry" ]]; then
        tlog_error "$tag" "No Junie release found for platform: %s" "$platform"

        return 1
    fi

    version="$(printf '%s\n' "$entry" | grep -o '"version":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"
    url="$(printf '%s\n' "$entry" | grep -o '"downloadUrl":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"
    checksum="$(printf '%s\n' "$entry" | grep -o '"sha256":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"

    if [[ -z "$version" || -z "$url" || ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
        tlog_error "$tag" "Failed to parse the Junie release index"

        return 1
    fi

    result_ref[VERSION]="$version"
    result_ref[URL]="$url"
    result_ref[CHECKSUM]="$checksum"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local platform
    local -A release=()
    local archive_file

    valid_install_target "$canonical_id" "$raw_install_path" "JUNIE_INSTALL_DIR" || return $?

    platform="$(__resolve_junie_platform "$canonical_id")" || return $?
    __resolve_junie_release "$canonical_id" "$platform" release || return $?

    tlog_info "pre-install:$canonical_id" "Downloading Junie %s (%s)" \
        "${release[VERSION]}" "$platform"
    stateful_download "$canonical_id" "ARCHIVE_FILE" "${release[URL]}" ".zip" 0 || return $?

    archive_file="$(get_state "ARCHIVE_FILE")" || return $?
    if [[ "$(sha256sum "$archive_file" | awk '{ print $1 }')" != "${release[CHECKSUM]}" ]]; then
        tlog_error "pre-install:$canonical_id" "Checksum verification failed"
        rm -f -- "$archive_file"

        return 1
    fi

    tlog_info "pre-install:$canonical_id" "Checksum verified"
    save_states "$canonical_id"
}

main "$CANONICAL_ID" "${JUNIE_INSTALL_DIR:-$INSTALL_DIR/junie}"
