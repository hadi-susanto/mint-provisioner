#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/install-target.sh"
source "$LIB_INSTALLER/state.sh"

__download_bootstrap_script() {
    local canonical_id="$1"
    local tag="pre-install:$canonical_id"
    local bootstrap_url="https://get.sdkman.io"
    local script_file

    if ! script_file="$(mktemp --suffix=.sh)"; then
        tlog_error "$tag" "Failed to create a temporary bootstrap file"

        return 2
    fi

    if ! download_file "$canonical_id" "$bootstrap_url" "$script_file"; then
        tlog_error "$tag" "Failed to download %s" "$bootstrap_url"
        rm -f -- "$script_file"

        return 3
    fi

    printf '%s\n' "$script_file"
}

__extract_metadata() {
    local canonical_id="$1"
    local script_file="$2"
    local env_name="$3"
    local tag="pre-install:$canonical_id"
    local value

    if [[ ! "$env_name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        tlog_error "$tag" "Invalid SDKMAN! metadata variable: %s" "$env_name"

        return 4
    fi

    if ! value="$(
        awk -F'"' -v env_name="$env_name" \
            '$0 ~ "^export " env_name "=" { print $2; exit }' \
            "$script_file"
    )"; then
        tlog_error "$tag" "Failed to extract SDKMAN! metadata: %s" "$env_name"

        return 5
    fi

    if [[ -z "$value" ]]; then
        tlog_error "$tag" "SDKMAN! metadata is empty or missing: %s" "$env_name"

        return 6
    fi

    printf '%s\n' "$value"
}

__download_sdkman_artifact() {
    local canonical_id="$1"
    local url="$2"
    local suffix="$3"
    local state_name="$4"
    local tag="pre-install:$canonical_id"
    local artifact_file

    if ! artifact_file="$(mktemp --suffix="$suffix")"; then
        tlog_error "$tag" "Failed to create a temporary SDKMAN! artifact: %s" "$state_name"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$artifact_file"; then
        tlog_error "$tag" "Failed to download SDKMAN! artifact: %s" "$state_name"
        rm -f -- "$artifact_file"

        return 3
    fi

    printf '%s\n' "$artifact_file"
}

__cleanup_and_return() {
    local rc="$1"
    shift

    if (( $# > 0 )); then
        rm -f -- "$@" || true
    fi

    return "$rc"
}

__save_sdkman_states() {
    local canonical_id="$1"
    local sdkman_service="$2"
    local sdkman_version="$3"
    local sdkman_native_version="$4"
    local standard_file="$5"
    local native_file="$6"
    local candidates_file="$7"
    local tag="pre-install:$canonical_id"

    if ! set_state "SDKMAN_SERVICE" "$sdkman_service"; then
        tlog_error "$tag" "Failed to save state: SDKMAN_SERVICE"

        return 11
    fi

    if ! set_state "SDKMAN_VERSION" "$sdkman_version"; then
        tlog_error "$tag" "Failed to save state: SDKMAN_VERSION"

        return 12
    fi

    if ! set_state "SDKMAN_NATIVE_VERSION" "$sdkman_native_version"; then
        tlog_error "$tag" "Failed to save state: SDKMAN_NATIVE_VERSION"

        return 13
    fi

    if ! set_state "STANDARD_FILE" "$standard_file"; then
        tlog_error "$tag" "Failed to save state: STANDARD_FILE"

        return 14
    fi

    if ! set_state "NATIVE_FILE" "$native_file"; then
        tlog_error "$tag" "Failed to save state: NATIVE_FILE"

        return 15
    fi

    if ! set_state "CANDIDATES_FILE" "$candidates_file"; then
        tlog_error "$tag" "Failed to save state: CANDIDATES_FILE"

        return 16
    fi

    if ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to persist installation state"

        return 17
    fi
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local tag="pre-install:$canonical_id"
    local sdkman_platform="linuxx64"
    local candidates_file
    local -a files=()
    local install_path
    local native_file
    local script_file
    local sdkman_native_version
    local sdkman_service
    local sdkman_version
    local standard_file
    local url

    install_path="$(resolve_install_target "$canonical_id" "$raw_install_path")" || return $?

    tlog_info "$tag" "Downloading the SDKMAN! bootstrap script to resolve versions"
    script_file="$(__download_bootstrap_script "$canonical_id")" || return $?
    files+=("$script_file")

    sdkman_service="$(
        __extract_metadata "$canonical_id" "$script_file" "SDKMAN_SERVICE"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?

    sdkman_version="$(
        __extract_metadata "$canonical_id" "$script_file" "SDKMAN_VERSION"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?

    sdkman_native_version="$(
        __extract_metadata "$canonical_id" "$script_file" "SDKMAN_NATIVE_VERSION"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?

    tlog_info "$tag" "Resolved SDKMAN! version: %s" "$sdkman_version"
    tlog_info "$tag" "Resolved SDKMAN! native version: %s" "$sdkman_native_version"

    url="${sdkman_service}/broker/download/sdkman/install/${sdkman_version}/${sdkman_platform}"
    standard_file="$(
        __download_sdkman_artifact "$canonical_id" "$url" ".zip" "STANDARD_FILE"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?
    files+=("$standard_file")

    url="${sdkman_service}/broker/download/native/install/${sdkman_native_version}/${sdkman_platform}"
    native_file="$(
        __download_sdkman_artifact "$canonical_id" "$url" ".zip" "NATIVE_FILE"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?
    files+=("$native_file")

    url="${sdkman_service}/candidates/all"
    candidates_file="$(
        __download_sdkman_artifact "$canonical_id" "$url" ".txt" "CANDIDATES_FILE"
    )" || __cleanup_and_return "$?" "${files[@]}" || return $?
    files+=("$candidates_file")

    __save_sdkman_states \
        "$canonical_id" \
        "$sdkman_service" \
        "$sdkman_version" \
        "$sdkman_native_version" \
        "$standard_file" \
        "$native_file" \
        "$candidates_file" || __cleanup_and_return "$?" "${files[@]}" || return $?

    if ! rm -f -- "$script_file"; then
        tlog_warn "$tag" "Failed to remove the temporary bootstrap script: %s" "$script_file"
    fi

    tlog_info "$tag" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID" "${SDKMAN_INSTALL_DIR:-$INSTALL_DIR/sdkman}"
