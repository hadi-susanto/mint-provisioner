#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GITHUB_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GITHUB_LOADED=1

source "$LIB_COMMON/common.sh"

##
# github_find_release_asset
#
# Finds one matching asset in the latest GitHub release, with its SHA-256
# digest when GitHub provides one.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   owner - GitHub repository owner.
#   repository - GitHub repository name.
#   pattern - Extended regular expression matched against asset URLs.
#   result_name - Name of the associative array that receives [URL] and
#       [SHA256]. SHA256 is "sha256:<hex>", or empty when GitHub has no digest
#       for the asset or jq is unavailable.
#
# Return:
#   1 - The GitHub release API request failed or could not be parsed.
#   2 - No asset, or more than one asset, matched the pattern.
#
github_find_release_asset() {
    local canonical_id="$1"
    local owner="$2"
    local repository="$3"
    local pattern="$4"
    local -n asset_ref="$5"
    local tag="github:$canonical_id"

    local api_url="https://api.github.com/repos/$owner/$repository/releases/latest"
    local body
    local assets
    local url
    local digest
    local -a matched_urls=()
    local -a matched_digests=()

    asset_ref=()

    tlog_info "$tag" "Finding latest GitHub release: %s" "$api_url"

    local -a curl_args=(-fsSL)

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    if ! body="$(curl "${curl_args[@]}" "$api_url")"; then
        tlog_error "$tag" "Failed to fetch the GitHub release API"

        return 1
    fi

    # Each line is "<url><TAB><digest>"; the digest is empty without jq.
    if command -v jq >/dev/null 2>&1; then
        if ! assets="$(printf '%s\n' "$body" |
            jq -r '.assets[] | [.browser_download_url, (.digest // "")] | @tsv')"; then
            tlog_error "$tag" "Failed to parse the GitHub release response"

            return 1
        fi
    else
        assets="$(printf '%s\n' "$body" | grep -o 'https://[^\"]*' || true)"
    fi

    while IFS=$'\t' read -r url digest; do
        if [[ -n "$url" && "$url" =~ $pattern ]]; then
            matched_urls+=("$url")
            matched_digests+=("$digest")
        fi
    done <<< "$assets"

    if (( ${#matched_urls[@]} == 0 )); then
        tlog_error "$tag" "No GitHub release asset matched: %s" "$pattern"
        tlog_info "$tag" "Please visit: https://github.com/$owner/$repository/releases to find updated release"

        return 2
    fi

    if (( ${#matched_urls[@]} > 1 )); then
        tlog_error "$tag" "Multiple GitHub release assets matched: %s" "$pattern"
        printf '%s\n' "${matched_urls[@]}" >&2

        return 2
    fi

    asset_ref[URL]="${matched_urls[0]}"
    asset_ref[SHA256]="${matched_digests[0]}"
}

##
# github_find_release
#
# Finds one matching asset URL in the latest GitHub release. Prefer
# github_find_release_asset when the download should be checksum-verified.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   owner - GitHub repository owner.
#   repository - GitHub repository name.
#   pattern - Extended regular expression matched against asset URLs.
#
# Output:
#   Prints the matching asset URL to standard output.
#
# Return:
#   1 - The GitHub release API request failed or could not be parsed.
#   2 - No asset, or more than one asset, matched the pattern.
#
github_find_release() {
    local -A release_asset=()

    github_find_release_asset "$1" "$2" "$3" "$4" release_asset || return $?
    printf '%s\n' "${release_asset[URL]}"
}
