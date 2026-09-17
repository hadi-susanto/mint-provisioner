#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GITHUB_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GITHUB_LOADED=1

source "$LIB_COMMON/common.sh"

##
# github_find_release
#
# Finds one matching asset in the latest GitHub release.
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
#   0 - Exactly one matching asset was found.
#   1 - The supplied arguments are invalid.
#   2 - The GitHub release API request failed.
#   3 - No release asset matched the pattern.
#   4 - Multiple release assets matched the pattern.
#   5 - The GitHub response could not be parsed.
#
github_find_release() {
    local canonical_id="$1"
    local owner="$2"
    local repository="$3"
    local pattern="$4"
    local tag="github:$canonical_id"

    local api_url="https://api.github.com/repos/$owner/$repository/releases/latest"
    local body
    local urls
    local matches
    local count

    tlog_info "$tag" "Finding latest GitHub release: %s" "$api_url"

    if ! body="$(curl -fsSL "$api_url")"; then
        tlog_error "$tag" "Failed to fetch the GitHub release API"

        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        if ! urls="$(printf '%s\n' "$body" | jq -r '.assets[].browser_download_url')"; then
            tlog_error "$tag" "Failed to parse the GitHub release response"

            return 1
        fi
    else
        urls="$(printf '%s\n' "$body" | grep -o 'https://[^\"]*' || true)"
    fi

    matches="$(printf '%s\n' "$urls" | grep -E "$pattern" || true)"
    count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)"

    if (( count == 0 )); then
        tlog_error "$tag" "No GitHub release asset matched: %s" "$pattern"
        tlog_info "$tag" "Please visit: https://github.com/$owner/$repository/releases to find updated release"

        return 2
    fi

    if (( count > 1 )); then
        tlog_error "$tag" "Multiple GitHub release assets matched: %s" "$pattern"
        printf '%s\n' "$matches" >&2

        return 2
    fi

    printf '%s\n' "$matches"
}
