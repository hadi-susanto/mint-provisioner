#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GITLAB_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GITLAB_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/downloader.sh"

readonly __GITLAB_API_URL="https://gitlab.com/api/v4"

__gitlab_fetch_latest_release() {
    local tag="$1"
    local project="$2"
    local api_url="$__GITLAB_API_URL/projects/${project//\//%2F}/releases/permalink/latest"
    local -a curl_args=(-fsSL)
    local gitlab_token="${MP_GITLAB_TOKEN:-${GITLAB_TOKEN:-}}"

    if [[ -n "$gitlab_token" ]]; then
        curl_args+=(-H "PRIVATE-TOKEN: $gitlab_token")
    fi

    if ! curl "${curl_args[@]}" "$api_url"; then
        tlog_error "$tag" "Failed to fetch the GitLab release API"

        return 1
    fi
}

__gitlab_release_tag() {
    local body="$1"
    local tag_name

    if command -v jq >/dev/null 2>&1; then
        tag_name="$(printf '%s\n' "$body" | jq -r '.tag_name // ""')" || return 1
    else
        tag_name="$(printf '%s\n' "$body" | grep -o -m 1 '"tag_name": *"[^"]*"' || true)"
        tag_name="${tag_name%\"}"
        tag_name="${tag_name##*\"}"
    fi

    printf '%s\n' "$tag_name"
}

# Prints one release link URL per line.
__gitlab_release_links() {
    local tag="$1"
    local body="$2"
    local links

    if command -v jq >/dev/null 2>&1; then
        if ! links="$(printf '%s\n' "$body" |
            jq -r '.assets.links[]? | (.direct_asset_url // .url // empty)')"; then
            tlog_error "$tag" "Failed to parse the GitLab release response"

            return 1
        fi
    else
        links="$(printf '%s\n' "$body" |
            grep -o '"direct_asset_url": *"[^"]*"' |
            sed -E 's/.*"([^"]*)"$/\1/' || true)"
    fi

    printf '%s\n' "$links"
}

##
# gitlab_find_release_asset
#
# Finds one matching asset in the latest gitlab.com release, with its SHA-256
# checksum when the caller names the release's checksum list asset.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   project - GitLab project path, such as "gitlab-org/cli" or
#       "group/subgroup/project".
#   pattern - Extended regular expression matched against asset URLs.
#   result_name - Name of the associative array that receives [URL],
#       [SHA256], and [VERSION]. SHA256 is "sha256:<hex>", or empty when
#       sums_name is omitted. VERSION is the release tag, or empty when it
#       cannot be read.
#   sums_name - Optional file name of a SHA256SUMS-style asset in the same
#       release, such as "checksums.txt", used to fill SHA256.
#
# Return:
#   1 - The GitLab release API request failed or could not be parsed.
#   2 - No asset, or more than one asset, matched the pattern.
#   3 - The checksum list is missing, unreadable, or has no entry for the asset.
#
gitlab_find_release_asset() {
    local canonical_id="$1"
    local project="$2"
    local pattern="$3"
    local -n asset_ref="$4"
    local sums_name="${5:-}"
    local tag="gitlab:$canonical_id"

    local body
    local links
    local link_url
    local sums_url=""
    local checksum
    local -a matched_urls=()

    asset_ref=()

    tlog_info "$tag" "Finding latest GitLab release: %s" "$project"
    body="$(__gitlab_fetch_latest_release "$tag" "$project")" || return 1
    links="$(__gitlab_release_links "$tag" "$body")" || return 1

    while IFS= read -r link_url; do
        [[ -n "$link_url" ]] || continue

        if [[ "$link_url" =~ $pattern ]]; then
            matched_urls+=("$link_url")
        fi

        if [[ -n "$sums_name" && "${link_url##*/}" == "$sums_name" ]]; then
            sums_url="$link_url"
        fi
    done <<< "$links"

    if (( ${#matched_urls[@]} == 0 )); then
        tlog_error "$tag" "No GitLab release asset matched: %s" "$pattern"
        tlog_info "$tag" "Please visit: https://gitlab.com/$project/-/releases to find updated release"

        return 2
    fi

    if (( ${#matched_urls[@]} > 1 )); then
        tlog_error "$tag" "Multiple GitLab release assets matched: %s" "$pattern"
        printf '%s\n' "${matched_urls[@]}" >&2

        return 2
    fi

    asset_ref[URL]="${matched_urls[0]}"
    asset_ref[SHA256]=""
    asset_ref[VERSION]="$(__gitlab_release_tag "$body" || true)"

    if [[ -z "$sums_name" ]]; then
        return 0
    fi

    if [[ -z "$sums_url" ]]; then
        tlog_error "$tag" "The GitLab release has no checksum list: %s" "$sums_name"

        return 3
    fi

    if ! checksum="$(fetch_sha256_from_sums \
        "$canonical_id" "$sums_url" "${asset_ref[URL]##*/}")"; then
        return 3
    fi

    asset_ref[SHA256]="sha256:$checksum"
}

##
# gitlab_latest_release_version
#
# Reads the tag of the latest gitlab.com release.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   project - GitLab project path, such as "gitlab-org/cli".
#
# Output:
#   Prints the release tag to standard output.
#
# Return:
#   1 - The GitLab release API request failed or has no tag.
#
gitlab_latest_release_version() {
    local canonical_id="$1"
    local project="$2"
    local tag="gitlab:$canonical_id"
    local body
    local tag_name

    body="$(__gitlab_fetch_latest_release "$tag" "$project")" || return 1

    if ! tag_name="$(__gitlab_release_tag "$body")" || [[ -z "$tag_name" ]]; then
        tlog_error "$tag" "Failed to read the GitLab release tag"

        return 1
    fi

    printf '%s\n' "$tag_name"
}
