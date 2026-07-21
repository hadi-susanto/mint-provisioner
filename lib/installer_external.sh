#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

#
# github_find_release <module> <owner> <repo> <pattern>
#
# Description:
#   Fetches the latest GitHub release and returns exactly ONE asset
#   download URL matching the provided regex pattern.
#
# Contract:
#   - Returns exactly one matching URL on stdout
#   - Fails if no match is found
#   - Fails if multiple matches are found (to avoid ambiguity)
#
# Parameters:
#   module   - Log prefix identifier
#   owner    - GitHub org/user
#   repo     - GitHub repository name
#   pattern  - grep-compatible regex used to match asset URL
#
# Output:
#   stdout   - Single matched browser_download_url
#
# Exit codes:
#   0 - Success (exactly one match)
#   1 - Invalid arguments
#   2 - Network/API failure
#   3 - No matching asset found
#   4 - Multiple matching assets found (ambiguous)
#   5 - JSON parsing error (jq failure)
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

#
# download_file <module> <download_url> <output_file>
#
# Downloads a file from a URL.
#
# Parameters:
#   module       - Module name used for logging.
#   download_url - URL to download.
#   output_file  - Destination file path.
#
# Returns:
#   0 - Download successful.
#   1 - Invalid arguments.
#   2 - Download failed.
#
# Example:
#   download_file \
#       gui/flameshot \
#       "https://github.com/.../flameshot.deb" \
#       "/tmp/flameshot.deb"
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
