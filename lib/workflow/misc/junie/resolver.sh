#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_JUNIE_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_JUNIE_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"

readonly JUNIE_UPDATE_INFO_URL="https://raw.githubusercontent.com/jetbrains-junie/junie/main/update-info.jsonl"

##
# resolve_junie_platform <canonical_id>
#
# Maps the machine architecture to a Junie release platform.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#
# Output:
#   Prints the Junie platform, such as linux-amd64.
#
# Return:
#   1 - The architecture is not supported.
#
resolve_junie_platform() {
    local canonical_id="$1"
    local tag="platform:$canonical_id"

    case "$(uname -m)" in
        x86_64 | amd64)
            printf '%s\n' "linux-amd64"
            ;;
        aarch64 | arm64)
            printf '%s\n' "linux-aarch64"
            ;;
        *)
            tlog_error "$tag" "Unsupported architecture: %s" "$(uname -m)"

            return 1
            ;;
    esac
}

##
# resolve_junie_release <canonical_id> <platform> <result_name>
#
# Resolves the latest Junie release for a platform from the release index.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   platform - Junie platform from resolve_junie_platform.
#   result_name - Name of the associative array that receives [VERSION], [URL],
#       and [CHECKSUM].
#
# Return:
#   1 - The release index could not be downloaded or parsed.
#
resolve_junie_release() {
    local canonical_id="$1"
    local platform="$2"
    local result_name="$3"
    local tag="release:$canonical_id"
    local -n result_ref="$result_name"
    local jsonl
    local entry
    local release_line
    local version
    local url
    local checksum

    if ! jsonl="$(curl -fsSL "$JUNIE_UPDATE_INFO_URL")"; then
        tlog_error "$tag" "Failed to download the Junie release index"

        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        # Each line is "<version><TAB><url><TAB><sha256>"; the newest version sorts last.
        release_line="$(
            jq -r --arg platform "$platform" \
                'select(.platform == $platform) | [.version, .downloadUrl, .sha256] | @tsv' \
                <<<"$jsonl" 2>/dev/null |
                LC_ALL=C sort -t. -k1,1n -k2,2n |
                tail -1 || true
        )"

        if [[ -z "$release_line" ]]; then
            tlog_error "$tag" "No Junie release found for platform: %s" "$platform"

            return 1
        fi

        IFS=$'\t' read -r version url checksum <<<"$release_line"
    else
        entry="$(
            printf '%s\n' "$jsonl" |
                grep "\"platform\":\"$platform\"" |
                sed 's/.*"version":"\([^"]*\)".*/\1\t&/' |
                LC_ALL=C sort -t. -k1,1n -k2,2n |
                tail -1 |
                cut -f2- || true
        )"

        if [[ -z "$entry" ]]; then
            tlog_error "$tag" "No Junie release found for platform: %s" "$platform"

            return 1
        fi

        version="$(printf '%s\n' "$entry" | grep -o '"version":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"
        url="$(printf '%s\n' "$entry" | grep -o '"downloadUrl":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"
        checksum="$(printf '%s\n' "$entry" | grep -o '"sha256":"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')"
    fi

    if [[ -z "$version" || -z "$url" || ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
        tlog_error "$tag" "Failed to parse the Junie release index"

        return 1
    fi

    result_ref[VERSION]="$version"
    result_ref[URL]="$url"
    result_ref[CHECKSUM]="$checksum"
}
