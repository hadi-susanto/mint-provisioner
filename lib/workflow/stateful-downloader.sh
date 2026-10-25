#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"

##
# stateful_download
#
# Downloads an artifact to a temporary file and stores its path in a state.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   state_name - State key that receives the temporary file path.
#   url - URL of the file to download.
#   suffix - Temporary file suffix, such as ".deb"; may be empty.
#   auto_save - 1 to save states after setting the state (default), 0 to skip.
#   sha256 - Optional expected SHA-256 checksum checked with verify_sha256.
#       When empty, a warning says the download was not verified.
#   version - Optional artifact version stored in the VERSION state, which
#       install workflows record in the module registry.
#
# Return:
#   1 - The download, checksum verification, or state update failed.
#
stateful_download() {
    local canonical_id="$1"
    local state_name="$2"
    local url="$3"
    local suffix="$4"
    local auto_save="${5:-1}"
    local sha256="${6:-}"
    local version="${7:-}"
    local tag="downloader:$canonical_id"
    local temp_file

    if ! temp_file="$(mktemp --suffix=$suffix)"; then
        tlog_error "$tag" "Failed to create a temporary file"

        return 1
    fi

    if ! download_file "$canonical_id" "$url" "$temp_file"; then
        tlog_error "$tag" "Fail to download: $url"
        rm -f -- "$temp_file" || true

        return 1
    fi

    if ! verify_sha256 "$canonical_id" "$temp_file" "$sha256"; then
        rm -f -- "$temp_file" || true

        return 1
    fi
    
    if ! set_state "$state_name" "$temp_file"; then
        tlog_error "$tag" "Failed to set $state_name state"
        rm -f -- "$temp_file" || true

        return 1
    fi

    if [[ -n "$version" ]] && ! set_state "VERSION" "$version"; then
        tlog_error "$tag" "Failed to set VERSION state"
        rm -f -- "$temp_file" || true

        return 1
    fi

    if (( ! $auto_save )); then
        tlog_info "$tag" "Skipping automatic state save; explicitly requested by caller"

        return 0
    fi

    if ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to save states for $canonical_id"
        rm -f -- "$temp_file" || true

        return 1
    fi

    return 0
}
