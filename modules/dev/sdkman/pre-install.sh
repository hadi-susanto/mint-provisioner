#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -r SDKMAN_API="https://api.sdkman.io/2"

__resolve_sdkman_latest_version() {
    local canonical_id="$1"
    local type="$2"
    local tag="sdk-version:$canonical_id"
    local version
    local status

    tlog_info "$tag" "Querying SDKMAN! %s version" "$type"
    if version="$(curl -fsSL "$SDKMAN_API/broker/version/sdkman/$type/stable")"; then
        tlog_info "$tag" "Resolved SDKMAN! %s version: %s" "$type" "$version"
        printf '%s\n' "$version"

        return 0
    else
        status=$?
        tlog_error "$tag" "Fail to obtain SDKMAN! %s latest version" "$type"

        return "$status"
    fi
}

__download_artifacts() {
    local canonical_id="$1"
    local url

    url="${SDKMAN_API}/broker/download/sdkman/install/${sdkman_version}/linuxx64"
    stateful_download "$canonical_id" "STANDARD_FILE" "$url" ".zip" 0 || return $?
    url="${SDKMAN_API}/broker/download/native/install/${sdkman_native_version}/linuxx64"
    stateful_download "$canonical_id" "NATIVE_FILE" "$url" ".zip" 0 || return $?
    url="${SDKMAN_API}/candidates/all"
    stateful_download "$canonical_id" "CANDIDATES_FILE" "$url" ".txt" 0 || return $?

    save_states "$canonical_id" || $return $?
    tlog_info "pre-install:$canonical_id" "SDKMAN! states saved"
}

__cleanup_artifacts() {
    local canonical_id="$1"
    local tag="artifact-cleanup:$canonical_id"
    local key
    local file

    for key in "STANDARD_FILE" "NATIVE_FILE" "CANDIDATES_FILE"; do
        if file="$(get_state "$key")"; then
            tlog_info "$tag" "Deleting previously downloaded file: %s" "$file"
            rm -f -- "$file"
        else
            tlog_info "$tag" "%s state not exists" "$key"
        fi
    done
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local sdkman_version
    local sdkman_native_version
    local status

    valid_install_target "$canonical_id" "$raw_install_path" "SDKMAN_INSTALL_DIR" || return $?
    sdkman_version="$(__resolve_sdkman_latest_version "$canonical_id" "script")" || return $?
    if ! set_state "SDKMAN_VERSION" "$sdkman_version"; then
        tlog_error "$tag" "Failed to save state: SDKMAN_VERSION"

        return 1
    fi
    sdkman_native_version="$(__resolve_sdkman_latest_version "$canonical_id" "native")" || return $?
     if ! set_state "SDKMAN_NATIVE_VERSION" "$sdkman_native_version"; then
        tlog_error "$tag" "Failed to save state: SDKMAN_NATIVE_VERSION"

        return 1
    fi
    if __download_artifacts "$canonical_id"; then
        :
    else
        status=$?
        __cleanup_artifacts "$canonical_id"

        return "$status"
    fi
}

main "$CANONICAL_ID" "${SDKMAN_INSTALL_DIR:-$INSTALL_DIR/sdkman}"
