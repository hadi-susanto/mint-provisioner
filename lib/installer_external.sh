#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

##
# Finds exactly one matching asset URL in the latest GitHub release.
#
# Parameters:
#   module     Canonical module ID used for logging.
#   owner      GitHub repository owner.
#   repo       GitHub repository name.
#   pattern    Extended regular expression matched against asset URLs.
#
# Output:
#   Prints the single matching download URL.
#
# Returns:
#   1 for invalid arguments; 2 for API failure; 3 for no match; 4 for multiple
#   matches; 5 when jq cannot parse the response.
#
github_find_release() {
    local module="${1:-}"
    local owner="${2:-}"
    local repo="${3:-}"
    local pattern="${4:-}"

    local api_url="https://api.github.com/repos/${owner}/${repo}/releases/latest"

    log_info "[github_find_release] [$module] Finding latest release from: $api_url"
    log_info "[github_find_release] [$module] Regex pattern: $pattern"

    if [[ -z "$module" || -z "$owner" || -z "$repo" || -z "$pattern" ]]; then
        log_error "[github_find_release] [$module] Missing required arguments"

        return 1
    fi

    local body
    body="$(curl -fsSL "$api_url")" || {
        log_error "[github_find_release] [$module] Failed to fetch GitHub API"

        return 2
    }

    local urls

    if command -v jq >/dev/null 2>&1; then
        urls="$(printf '%s\n' "$body" | jq -r '.assets[].browser_download_url')" || {
            log_error "[github_find_release] [$module] Failed to parse JSON"

            return 5
        }
    else
        urls="$(printf '%s\n' "$body" | grep -o 'https://[^"]*' || true)"
    fi

    local matches
    matches="$(printf '%s\n' "$urls" | grep -E "$pattern" || true)"

    local count
    count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)"

    if [[ "$count" -eq 0 ]]; then
        log_error "[github_find_release] [$module] No matching asset found"

        return 3
    fi

    if [[ "$count" -gt 1 ]]; then
        log_error "[github_find_release] [$module] Multiple matching assets found:"
        printf '%s\n' "$matches" >&2

        return 4
    fi

    echo "$matches"

    return 0
}

##
# Downloads a URL to a destination file.
#
# Parameters:
#   module          Canonical module ID used for logging.
#   download_url    URL to download.
#   output_file     Destination file path.
#
# Returns:
#   1 when arguments are missing; 2 when curl cannot download the file.
#
download_file() {
    local module="${1:-}"
    local download_url="${2:-}"
    local output_file="${3:-}"

    if [[ -z "$module" ]] || \
       [[ -z "$download_url" ]] || \
       [[ -z "$output_file" ]]; then
        log_error "[download_file] [$module] Missing required arguments"

        return 1
    fi

    log_info "[download_file] [$module] Source: $download_url"
    log_info "[download_file] [$module] Destination: $output_file"

    if ! curl -fL -o "$output_file" "$download_url"; then
        log_error "[download_file] [$module] '$download_url' download failed"

        return 2
    fi

    log_info "[download_file] [$module] '$download_url' downloaded"

    return 0
}
