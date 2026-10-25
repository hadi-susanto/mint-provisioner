#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_JETBRAINS_RELEASE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_JETBRAINS_RELEASE_LOADED=1

source "$LIB_COMMON/common.sh"

##
# jetbrains_latest_release <canonical_id> <release_code> <result_name>
#
# Resolves the latest JetBrains Linux release of a product. Requires jq.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   release_code - JetBrains product release code, such as IIU.
#   result_name - Name of the associative array that receives [DOWNLOAD_URL],
#       [CHECKSUM_URL], and [VERSION].
#
# Return:
#   1 - jq is not available.
#   2 - The release metadata could not be downloaded.
#   3 - The release metadata is incomplete or could not be parsed.
#
jetbrains_latest_release() {
    local canonical_id="$1"
    local release_code="$2"
    local -n release_ref="$3"
    local tag="metadata:$canonical_id"
    local metadata_url="https://data.services.jetbrains.com/products/releases?code=${release_code}&latest=true&type=release"
    local metadata_json
    local release_data
    local download_url
    local checksum_url
    local version

    release_ref=()

    if ! command -v jq >/dev/null 2>&1; then
        tlog_error "$tag" "jq is required to read JetBrains release metadata"

        return 1
    fi

    if ! metadata_json="$(curl -fsSL "$metadata_url")"; then
        tlog_error "$tag" "Failed to download JetBrains release metadata"

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
            <<< "$metadata_json"
    )"; then
        tlog_error "$tag" "Failed to resolve the latest JetBrains Linux release"

        return 3
    fi

    IFS=$'\t' read -r download_url checksum_url version <<< "$release_data"

    release_ref[DOWNLOAD_URL]="$download_url"
    release_ref[CHECKSUM_URL]="$checksum_url"
    release_ref[VERSION]="$version"
}
