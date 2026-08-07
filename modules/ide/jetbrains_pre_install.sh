#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_PRE_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_PRE_INSTALL_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/install-target.sh"
source "$LIB_INSTALLER/sudo-refresher.sh"
source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"

__auto_install_jq() {
    local canonical_id="$1"
    local tag="auto-jq:$canonical_id"
    local auto_install

    if command -v jq >/dev/null 2>&1; then
        tlog_info "$tag" "jq is already available"

        return 0
    fi

    auto_install="$(get_state "JETBRAINS_AUTO_INSTALL_JQ")" || return $?

    if [[ "$auto_install" != "true" ]]; then
        tlog_error "$tag" \
            "jq is required and automatic installation was not authorized"

        return 1
    fi

    tlog_info "$tag" "Installing required dependency: jq"

    source "$LIB_INSTALLER/apt.sh"
    if ! apt_install "$canonical_id" jq; then
        tlog_error "$tag" "Failed to install required dependency: jq"

        return 2
    fi

    if ! command -v jq >/dev/null 2>&1; then
        tlog_error "$tag" "jq is unavailable after dependency preparation"

        return 3
    fi

    return 0
}

__auto_install_aria2c() {
    local canonical_id="$1"
    local tag="auto-jq:$canonical_id"
    local auto_install

    if command -v aria2c >/dev/null 2>&1; then
        tlog_info "$tag" "aria2c is already available"

        return 0
    fi

    auto_install="$(get_state "JETBRAINS_AUTO_INSTALL_ARIA2")" || return $?

    if [[ "$auto_install" != "true" ]]; then
        tlog_info "$tag" \
            "aria2 installation was not authorized; using the standard downloader"

        return 0
    fi

    tlog_info "$tag" "Installing optional download accelerator: aria2"

    source "$LIB_INSTALLER/apt.sh"
    if ! apt_install "$canonical_id" jq; then
        tlog_error "$tag" "Failed to install optional download accelerator: aria2"

        return 1
    fi

    if ! command -v aria2c >/dev/null 2>&1; then
        tlog_error "$tag" "aria2c is unavailable after dependency preparation"

        return 2
    fi

    return 0
}

__cleanup_downloads() {    
    if (( $# > 0 )); then
        rm -f -- "$@" || true
    fi
}

__extract_metadata() {
    local canonical_id="$1"
    local release_code="$2"
    local result_name="$3"
    local tag="metadata:$canonical_id"
    local metadata_file
    local metadata_url
    local release_data
    local download_url
    local checksum_url
    local version

    declare -n result_ref="$result_name"
    result_ref=()

    metadata_url="https://data.services.jetbrains.com/products/releases?code=${release_code}&latest=true&type=release"

    if ! metadata_file="$(mktemp --suffix=.json)"; then
        tlog_error "$tag" "Failed to create metadata temporary file"

        return 1
    fi

    # Use plain cURL to download small metadata file
    if ! curl_download "$canonical_id" "$metadata_url" "$metadata_file"; then
        tlog_error "$tag" "Failed to download JetBrains release metadata"
        __cleanup_downloads "$metadata_file"

        return 2
    fi

    if ! release_data="$(
        jq -er \
            --arg code "$release_code" \
            '.[$code][0] as $release
             | [$release.downloads.linux.link,
                $release.downloads.linux.checksumLink,
                $release.version]
             | if all(.[]; type == "string" and length > 0)
               then @tsv
               else error("release download metadata is incomplete")
               end' \
            "$metadata_file"
    )"; then
        tlog_error "$tag" "Failed to resolve the latest JetBrains Linux release"
        __cleanup_downloads "$metadata_file"

        return 3
    fi

    __cleanup_downloads "$metadata_file"

    IFS=$'\t' read -r download_url checksum_url version <<< "$release_data"

    result_ref[DOWNLOAD_URL]="$download_url"
    result_ref[CHECKSUM_URL]="$checksum_url"
    result_ref[VERSION]="$version"

    return 0
}

__download_and_checksum() {
    local tag="$1"
    local download_url="$2"
    local checksum_url="$3"
    local archive_file="$4"
    local checksum_file=""
    local expected_checksum
    local actual_checksum
    local sudo_refresh_pid=""
    local download_status=0
    local refresh_stop_status=0

    if ! checksum_file="$(mktemp --suffix=.sha256)"; then
        tlog_error "$tag" "Failed to create checksum temporary file"
        __cleanup_downloads "$archive_file"

        return 1
    fi

    if ! curl_download "$canonical_id" "$checksum_url" "$checksum_file"; then
        tlog_error "$tag" "Failed to download the official checksum"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    tlog_info "$tag" "Refreshing sudo credential every 120 second(s)"
    if ! start_sudo_refresher "$tag" sudo_refresh_pid 120; then
        tlog_error "$tag" "Failed to start sudo credential refresh"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    download_file "$canonical_id" "$download_url" "$archive_file" || download_status=$?
    stop_sudo_refresher "$canonical_id" "$sudo_refresh_pid" || refresh_stop_status=$?

    if (( download_status != 0 )); then
        tlog_error "$tag" "Failed to download JetBrains installation archive"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    if (( refresh_stop_status != 0 )); then
        tlog_error "$tag" "Failed to stop sudo refresher"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    expected_checksum="$(awk 'NR == 1 { print $1 }' "$checksum_file")"
    if [[ ! "$expected_checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
        tlog_error "$tag" "Official checksum data is invalid"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi
    
    tlog_info "$tag" "Calculating checksum of $archive_file"
    if ! actual_checksum="$(sha256sum "$archive_file" | awk '{ print $1 }')"; then
        tlog_error "$tag" "Failed to calculate the archive checksum"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    if [[ "${actual_checksum,,}" != "${expected_checksum,,}" ]]; then
        tlog_error "$tag" "JetBrains archive checksum verification failed"
        __cleanup_downloads "$archive_file" "$checksum_file"

        return 1
    fi

    tlog_info "$tag" "JetBrains archive checksum verified"
    __cleanup_downloads "$checksum_file"

    return 0
}

main() {
    local canonical_id="$1"
    local product_release_code="$2"
    local product_name="$3"
    local raw_install_path="$4"
    local tag="pre-install:$canonical_id"
    local -A metadata
    local archive_file

    load_states "$canonical_id" || return $?
    tlog_info "$tag" "Validating %s installation requirements" "$product_name"
    if ! command -v sha256sum >/dev/null 2>&1; then
        tlog_error "$tag" "sha256sum is required for %s installation" "$product_name"

        return 3
    fi
    __auto_install_jq "$canonical_id" || return $?
    __auto_install_aria2c "$canonical_id" || return $?
    resolve_install_target "$canonical_id" "$raw_install_path" >/dev/null || return $?

    tlog_info "$tag" "Resolving %s metadata from JetBrains" "$product_name"
    __extract_metadata "$canonical_id" "$product_release_code" metadata || return $?

    tlog_info "$tag" "Metadata resolved, downloading the artifact"
    if ! archive_file="$(mktemp --suffix=.tar.gz)"; then
        tlog_error "$tag" "Failed to create archive temporary file"

        return 1
    fi
    __download_and_checksum \
        "$canonical_id" \
        "${metadata[DOWNLOAD_URL]}" \
        "${metadata[CHECKSUM_URL]}" \
        "$archive_file"
    
    if ! set_state "JETBRAINS_ARCHIVE_FILE" "$archive_file" || \
        ! set_state "JETBRAINS_VERSION" "${metadata[VERSION]}" || \
        ! save_states "$canonical_id"; then
        __cleanup_downloads "$archive_file"

        return 1
    fi
}
