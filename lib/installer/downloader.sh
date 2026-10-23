#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DOWNLOADER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# curl_download
#
# Downloads an artifact to a destination file using cURL
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   download_url - URL of the file to download.
#   output_file - Destination path for the downloaded file.
#
# Return:
#   0 - The file was downloaded successfully.
#   1 - The supplied arguments are invalid.
#   2 - The download failed.
#
curl_download() {
    local canonical_id="$1"
    local download_url="$2"
    local output_file="$3"
    local tag="curl:$canonical_id"

    if [[ -z "$canonical_id" || -z "$download_url" || -z "$output_file" ]]; then
        tlog_error "$tag" "A canonical ID, URL, and output file are required"

        return 1
    fi

    tlog_info "$tag" "Using curl with single connection"
    tlog_info "$tag" "Source: %s" "$download_url"
    tlog_info "$tag" "Destination: %s" "$output_file"

    if ! curl -fL -o "$output_file" "$download_url"; then
        tlog_error "$tag" "Download failed: %s" "$download_url"

        return 2
    fi

    tlog_info "$tag" "'%s' downloaded" "$download_url"

    return 0
}

##
# aria2c_download
#
# Downloads an artifact with four aria2 connections
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   download_url    URL to download.
#   output_file     Destination file path.
#
# Returns:
#   1 when required arguments are missing; 2 when the download fails.
#
aria2c_download() {
    local canonical_id="$1"
    local download_url="$2"
    local output_file="$3"
    local output_dir
    local output_name
    local control_file
    local tag="aria2c:$canonical_id"

    if [[ -z "$canonical_id" || -z "$download_url" || -z "$output_file" ]]; then
        tlog_error "$tag" "A canonical ID, URL, and output file are required"

        return 1
    fi

    output_dir="$(dirname -- "$output_file")"
    output_name="${output_file##*/}"
    control_file="${output_file}.aria2"

    tlog_info "$tag" "Using aria2c with 4 concurrent connections"
    tlog_info "$tag" "Source: %s" "$download_url"
    tlog_info "$tag" "Destination: %s" "$output_file"

    if ! aria2c \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        --max-connection-per-server=4 \
        --split=4 \
        --dir="$output_dir" \
        --out="$output_name" \
        "$download_url"
    then
        tlog_error "$tag" "'%s' download failed" "$download_url"
        rm -f "$control_file"

        return 2
    fi

    tlog_info "$tag" "'%s' downloaded" "$download_url"

    return 0
}

##
# verify_sha256
#
# Verifies a downloaded file against an expected SHA-256 checksum. An empty
# checksum logs a warning that the file is unverified and succeeds.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   file - Path of the file to verify.
#   expected_sha256 - Expected checksum as 64 hex characters, optionally
#       prefixed with "sha256:" as returned by the GitHub API. May be empty.
#
# Return:
#   0 - The checksum matched, or no checksum was supplied.
#   1 - The checksum is malformed or the file cannot be hashed.
#   3 - The checksum did not match.
#
verify_sha256() {
    local canonical_id="$1"
    local file="$2"
    local expected_sha256="${3#sha256:}"
    local tag="checksum:$canonical_id"
    local actual_sha256

    if [[ -z "$expected_sha256" ]]; then
        tlog_warn "$tag" "No checksum available; the download was not verified"

        return 0
    fi

    expected_sha256="${expected_sha256,,}"
    if [[ ! "$expected_sha256" =~ ^[0-9a-f]{64}$ ]]; then
        tlog_error "$tag" "Invalid SHA-256 checksum: %s" "$3"

        return 1
    fi

    if ! actual_sha256="$(sha256sum -- "$file")"; then
        tlog_error "$tag" "Failed to compute the SHA-256 checksum of %s" "$file"

        return 1
    fi

    actual_sha256="${actual_sha256%% *}"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        tlog_error "$tag" "Checksum mismatch for %s" "$file"
        tlog_error "$tag" "Expected: %s" "$expected_sha256"
        tlog_error "$tag" "Actual:   %s" "$actual_sha256"

        return 3
    fi

    tlog_info "$tag" "SHA-256 checksum verified"

    return 0
}

##
# fetch_sha256_from_sums
#
# Reads one file's checksum from a published SHA256SUMS-style list, where each
# line is "<sha256>  <file_name>" (as written by sha256sum).
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   sums_url - URL of the checksum list.
#   file_name - Name of the file whose checksum is wanted.
#
# Output:
#   Prints the 64-character SHA-256 checksum to standard output.
#
# Return:
#   1 - The checksum list could not be downloaded.
#   2 - The list has no valid checksum for the file.
#
fetch_sha256_from_sums() {
    local canonical_id="$1"
    local sums_url="$2"
    local file_name="$3"
    local tag="checksum:$canonical_id"
    local sums
    local checksum

    if ! sums="$(curl -fsSL "$sums_url")"; then
        tlog_error "$tag" "Failed to download the checksum list: %s" "$sums_url"

        return 1
    fi

    checksum="$(awk -v name="$file_name" \
        '$2 == name || $2 == "*" name { print $1; exit }' <<<"$sums")"

    if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
        tlog_error "$tag" "No SHA-256 checksum for %s in %s" "$file_name" "$sums_url"

        return 2
    fi

    printf '%s\n' "$checksum"
}

##
# download_file
#
# Donwload an artifact with aria2c when the binary available
# otherwise will fallback to cURL
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   download_url - URL of the file to download.
#   output_file - Destination path for the downloaded file.
#
# Return:
#   0 - The file was downloaded successfully.
#   1 - The supplied arguments are invalid.
#   2 - The download failed.
#
download_file() {
    local canonical_id="$1"
    local download_url="$2"
    local output_file="$3"

    if command -v aria2c >/dev/null 2>&1; then
        aria2c_download "$canonical_id" "$download_url" "$output_file"
    else
        curl_download "$canonical_id" "$download_url" "$output_file"
    fi
}
