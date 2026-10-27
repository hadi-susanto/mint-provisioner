#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_DOWNLOAD_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_DOWNLOAD_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/sudo-refresher.sh"
source "$LIB_WORKFLOW/jetbrains-release.sh"

__jetbrains_cleanup_downloads() {
    if (( $# > 0 )); then
        rm -f -- "$@" || true
    fi
}

__jetbrains_download_artifact() {
    local canonical_id="$1"
    local url="$2"
    local target="$3"
    local tag="download:$canonical_id"
    local sudo_refresh_pid=""
    local download_status=0
    local refresh_stop_status=0

    tlog_info "$tag" "Refreshing sudo credential every 120 second(s)"
    if ! start_sudo_refresher "$tag" sudo_refresh_pid 120; then
        tlog_error "$tag" "Failed to start sudo credential refresh"
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    download_file "$canonical_id" "$url" "$target" || download_status=$?
    stop_sudo_refresher "$canonical_id" "$sudo_refresh_pid" || refresh_stop_status=$?

    if (( download_status != 0 )); then
        tlog_error "$tag" "Failed to download JetBrains installation archive"
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    if (( refresh_stop_status != 0 )); then
        tlog_error "$tag" "Failed to stop sudo refresher"
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    return 0
}

__jetbrains_checksum_artifact() {
    local canonical_id="$1"
    local url="$2"
    local target="$3"
    local tag="checksum:$canonical_id"
    local checksum_file=""
    local expected_checksum

    if ! checksum_file="$(mktemp --suffix=.sha256)"; then
        tlog_error "$tag" "Failed to create checksum temporary file"
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    if ! curl_download "$canonical_id" "$url" "$checksum_file"; then
        tlog_error "$tag" "Failed to download the official checksum"
        __jetbrains_cleanup_downloads "$target" "$checksum_file"

        return 1
    fi

    expected_checksum="$(awk 'NR == 1 { print $1 }' "$checksum_file")"
    __jetbrains_cleanup_downloads "$checksum_file"

    # An empty checksum would only warn, but JetBrains always publishes one.
    if [[ -z "$expected_checksum" ]]; then
        tlog_error "$tag" "Official checksum data is empty"
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    if ! verify_sha256 "$canonical_id" "$target" "$expected_checksum"; then
        __jetbrains_cleanup_downloads "$target"

        return 1
    fi

    return 0
}

##
# jetbrains_download_release <canonical_id> <release_code> <product_name>
#
# Downloads the latest stable release archive of a JetBrains product, verifies
# it against the official checksum, and saves JETBRAINS_ARCHIVE_FILE and
# VERSION in the module state. Used by pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID whose states are already loaded.
#   release_code - JetBrains product release code, such as IIU.
#   product_name - Product name used in log messages.
#
# Return:
#   1 - Metadata, download, checksum, or state handling failed.
#
jetbrains_download_release() {
    local canonical_id="$1"
    local product_release_code="$2"
    local product_name="$3"
    local tag="download:$canonical_id"
    local -A release_metadata=()
    local archive_file

    tlog_info "$tag" "Resolving %s metadata from JetBrains" "$product_name"
    jetbrains_latest_release "$canonical_id" "$product_release_code" release_metadata || return $?

    tlog_info "$tag" "Metadata resolved, downloading %s artifact" "$product_name"
    if ! archive_file="$(mktemp --suffix=.tar.gz)"; then
        tlog_error "$tag" "Failed to create archive temporary file"

        return 1
    fi
    __jetbrains_download_artifact "$canonical_id" "${release_metadata[DOWNLOAD_URL]}" "$archive_file" || return $?
    __jetbrains_checksum_artifact "$canonical_id" "${release_metadata[CHECKSUM_URL]}" "$archive_file" || return $?

    if ! set_state "JETBRAINS_ARCHIVE_FILE" "$archive_file" ||
        ! set_state "VERSION" "${release_metadata[VERSION]}"; then
        __jetbrains_cleanup_downloads "$archive_file"

        return 1
    fi

    if save_states "$canonical_id"; then
        return 0
    fi

    __jetbrains_cleanup_downloads "$archive_file"

    return 1
}
