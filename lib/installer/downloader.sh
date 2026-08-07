#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DOWNLOADER_LOADED=1

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
    local tag="curl"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if [[ -z "$canonical_id" || -z "$download_url" || -z "$output_file" ]]; then
        tlog_error "$tag" "A canonical ID, URL, and output file are required"

        return 1
    fi

    tlog_info "$tag" "Using curl with single connection"
    tlog_info "$tag" "Source: $download_url"
    tlog_info "$tag" "Destination: $output_file"

    if ! curl -fL -o "$output_file" "$download_url"; then
        tlog_error "$tag" "Download failed: %s" "$download_url"

        return 2
    fi

    tlog_info "$tag" "'$download_url' downloaded"

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
    local tag="curl"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if [[ -z "$canonical_id" || -z "$download_url" || -z "$output_file" ]]; then
        tlog_error "$tag" "A canonical ID, URL, and output file are required"

        return 1
    fi

    output_dir="$(dirname -- "$output_file")"
    output_name="${output_file##*/}"
    control_file="${output_file}.aria2"

    tlog_info "$tag" "Using aria2c with 4 concurrent connections"
    tlog_info "$tag" "Source: $download_url"
    tlog_info "$tag" "Destination: $output_file"

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

    tlog_info "$tag" "'$download_url' downloaded"

    return 0
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
    local canonical_id="${1:-}"
    local download_url="${2:-}"
    local output_file="${3:-}"
    
    if command -v aria2c >/dev/null 2>&1; then
        aria2c_download "$canonical_id" "$download_url" "$output_file"
    else
        curl_download "$canonical_id" "$download_url" "$output_file"
    fi
}
