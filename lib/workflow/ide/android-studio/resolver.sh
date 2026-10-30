#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_ANDROID_STUDIO_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_ANDROID_STUDIO_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# android_studio_latest_release <canonical_id> <result_name>
#
# Resolves the latest stable Android Studio Linux release from the official
# release feed.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   result_name - Name of the associative array that receives [URL], [SHA256],
#       and [VERSION].
#
# Return:
#   1 - The release feed could not be downloaded.
#   2 - No stable Linux release was found in the feed.
#
android_studio_latest_release() {
    local canonical_id="$1"
    local -n result_ref="$2"
    local tag="metadata:$canonical_id"
    local feed_url="https://jb.gg/android-studio-releases-list.xml"
    local feed_xml
    local row
    local row_url
    local row_sha256
    local row_version

    result_ref=()

    if ! feed_xml="$(curl -fsSL "$feed_url")"; then
        tlog_error "$tag" "Failed to download the Android Studio release feed"

        return 1
    fi

    # The feed lists the newest release first; take the first Release item.
    row="$(
        awk '
            /<item>/ { version = ""; channel = ""; url = ""; sha256 = ""; want = 0 }
            /<version>/ { version = $0; gsub(/.*<version>|<\/version>.*/, "", version) }
            /<channel>/ { channel = $0; gsub(/.*<channel>|<\/channel>.*/, "", channel) }
            /<link>.*-linux\.tar\.gz<\/link>/ { url = $0; gsub(/.*<link>|<\/link>.*/, "", url); want = 1 }
            want && /<checksum>/ { sha256 = $0; gsub(/.*<checksum>|<\/checksum>.*/, "", sha256); want = 0 }
            /<\/item>/ && channel == "Release" && url != "" && sha256 != "" {
                printf "%s\t%s\t%s\n", url, sha256, version
                exit
            }
        ' <<< "$feed_xml"
    )"

    IFS=$'\t' read -r row_url row_sha256 row_version <<< "$row"
    if [[ -z "$row_url" || -z "$row_sha256" || -z "$row_version" ]]; then
        tlog_error "$tag" "No stable Android Studio Linux release found in the release feed"

        return 2
    fi

    result_ref[URL]="$row_url"
    result_ref[SHA256]="$row_sha256"
    result_ref[VERSION]="$row_version"
}
