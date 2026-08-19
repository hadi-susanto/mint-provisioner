#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"

stateful_download() {
    local canonical_id="$1"
    local state_name="$2"
    local url="$3"
    local suffix="$4"
    local auto_save="${5:-1}"
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
    
    if ! set_state "$state_name" "$temp_file"; then
        tlog_error "$tag" "Failed to set $state_name state"
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
