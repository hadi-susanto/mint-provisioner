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
# Scans a SourceForge directory and prints its latest matching child directory.
#
# Returns:
#   2 when the directory cannot be accessed; 3 when no child directory matches.
#
__sourceforge_find_latest_version() {
    local module="$1"
    local release_url="$2"
    local release_path="$3"
    local version_regex="$4"
    local body

    if ! body="$(curl -fsSL "$release_url")"; then
        log_error "[sourceforge_find_release] [$module] Failed to access SourceForge release directory: $release_url"

        return 2
    fi

    local entry_url
    local version
    local -a versions=()

    while IFS= read -r entry_url; do
        entry_url="${entry_url#\"url\":\"}"
        entry_url="${entry_url%\"}"

        if [[ "$entry_url" != "$release_path"* || "$entry_url" != */ ]]; then
            continue
        fi

        version="${entry_url#"$release_path"}"
        version="${version%/}"

        if [[ -z "$version" || "$version" == */* ]]; then
            continue
        fi

        if [[ "$version" =~ $version_regex ]]; then
            versions+=("$version")
        fi
    done < <(printf '%s\n' "$body" | grep -oE '"url":"[^"]+"' || true)

    if ((${#versions[@]} == 0)); then
        log_error "[sourceforge_find_release] [$module] No release directory matched regex: $version_regex"

        return 3
    fi

    printf '%s\n' "${versions[@]}" | sort -V | tail -n 1
}

##
# Scans a SourceForge version directory and prints one matching download URL.
#
# Returns:
#   4 when the directory cannot be accessed; 5 when no artifact matches;
#   6 when multiple artifacts match.
#
__sourceforge_find_artifact() {
    local module="$1"
    local version_url="$2"
    local artifact_regex="$3"
    local body

    if ! body="$(curl -fsSL "${version_url}/")"; then
        log_error "[sourceforge_find_release] [$module] Failed to access SourceForge release directory: ${version_url}/"

        return 4
    fi

    local artifact_url
    local filename
    local -a matches=()

    while IFS= read -r artifact_url; do
        if [[ "$artifact_url" != "${version_url}/"* || "$artifact_url" != */download ]]; then
            continue
        fi

        filename="${artifact_url#"${version_url}/"}"
        filename="${filename%/download}"

        if [[ -z "$filename" || "$filename" == */* ]]; then
            continue
        fi

        if [[ "$filename" =~ $artifact_regex ]]; then
            matches+=("$artifact_url")
        fi
    done < <(
        printf '%s\n' "$body" |
            grep -oE 'https://sourceforge\.net/projects/[^"[:space:]]+/download' |
            sort -u || true
    )

    if ((${#matches[@]} == 0)); then
        log_error "[sourceforge_find_release] [$module] No artifact matched regex: $artifact_regex"

        return 5
    fi

    if ((${#matches[@]} > 1)); then
        log_error "[sourceforge_find_release] [$module] Multiple artifacts matched regex: $artifact_regex"
        printf '%s\n' "${matches[@]}" >&2

        return 6
    fi

    printf '%s\n' "${matches[0]}"
}

##
# Finds exactly one matching artifact in the latest SourceForge release.
#
# Parameters:
#   canonical_id     Canonical module ID used for logging.
#   project_name     SourceForge project name.
#   release_dir      Project-relative release directory, which may be nested.
#   version_regex    Extended regular expression matched against directories.
#   artifact_regex   Extended regular expression matched against filenames.
#
# Output:
#   Prints the single matching artifact's complete /download URL.
#
# Returns:
#   1 for invalid arguments; 2 when the release directory cannot be accessed;
#   3 when no version matches; 4 when the latest version cannot be accessed;
#   5 when no artifact matches; 6 when multiple artifacts match.
#
sourceforge_find_release() {
    local canonical_id="${1:-}"
    local project_name="${2:-}"
    local release_dir="${3:-}"
    local version_regex="${4:-}"
    local artifact_regex="${5:-}"

    if [[ -z "$canonical_id" ||
          -z "$project_name" ||
          -z "$release_dir" ||
          -z "$version_regex" ||
          -z "$artifact_regex" ]]; then
        log_error "[sourceforge_find_release] [$canonical_id] Missing required arguments"

        return 1
    fi

    release_dir="${release_dir#/}"
    release_dir="${release_dir%/}"

    if [[ -z "$release_dir" ]]; then
        log_error "[sourceforge_find_release] [$canonical_id] SourceForge release directory must not be empty"

        return 1
    fi

    local release_url="https://sourceforge.net/projects/${project_name}/files/${release_dir}"
    local release_path="/projects/${project_name}/files/${release_dir}/"
    local version

    log_info "[sourceforge_find_release] [$canonical_id] Scanning release directory: ${release_url}/"
    log_info "[sourceforge_find_release] [$canonical_id] Version regex: $version_regex"

    version="$(__sourceforge_find_latest_version \
        "$canonical_id" \
        "${release_url}/" \
        "$release_path" \
        "$version_regex")" || return $?

    local version_url="${release_url}/${version}"

    log_info "[sourceforge_find_release] [$canonical_id] Latest matching version: $version"
    log_info "[sourceforge_find_release] [$canonical_id] Artifact regex: $artifact_regex"

    __sourceforge_find_artifact \
        "$canonical_id" \
        "$version_url" \
        "$artifact_regex"
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
