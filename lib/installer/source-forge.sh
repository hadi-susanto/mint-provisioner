#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_SOURCE_FORGE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_SOURCE_FORGE_LOADED=1

source "$LIB_COMMON/common.sh"

__sourceforge_find_latest_version() {
    local canonical_id="$1"
    local release_url="$2"
    local release_path="$3"
    local version_regex="$4"
    local tag="external:$canonical_id"
    local body
    local entry_url
    local version
    local -a versions=()

    if ! body="$(curl -fsSL "$release_url")"; then
        tlog_error "$tag" "Failed to access SourceForge directory: %s" "$release_url"

        return 2
    fi

    while IFS= read -r entry_url; do
        entry_url="${entry_url#\"url\":\"}"
        entry_url="${entry_url%\"}"

        if [[ "$entry_url" != "$release_path"* || "$entry_url" != */ ]]; then
            continue
        fi

        version="${entry_url#"$release_path"}"
        version="${version%/}"

        if [[ -n "$version" && "$version" != */* &&
            "$version" =~ $version_regex ]]; then
            versions+=("$version")
        fi
    done < <(printf '%s\n' "$body" | grep -oE '"url":"[^"]+"' || true)

    if (( ${#versions[@]} == 0 )); then
        tlog_error "$tag" "No SourceForge version matched: %s" "$version_regex"

        return 3
    fi

    printf '%s\n' "${versions[@]}" | sort -V | tail -n 1
}

__sourceforge_find_artifact() {
    local canonical_id="$1"
    local version_url="$2"
    local artifact_regex="$3"
    local tag="external:$canonical_id"
    local body
    local artifact_url
    local filename
    local -a matches=()

    if ! body="$(curl -fsSL "$version_url/")"; then
        tlog_error "$tag" "Failed to access SourceForge version: %s" "$version_url"

        return 4
    fi

    while IFS= read -r artifact_url; do
        if [[ "$artifact_url" != "$version_url/"* ||
            "$artifact_url" != */download ]]; then
            continue
        fi

        filename="${artifact_url#"$version_url/"}"
        filename="${filename%/download}"

        if [[ -n "$filename" && "$filename" != */* &&
            "$filename" =~ $artifact_regex ]]; then
            matches+=("$artifact_url")
        fi
    done < <(
        printf '%s\n' "$body" |
            grep -oE 'https://sourceforge\.net/projects/[^"[:space:]]+/download' |
            sort -u || true
    )

    if (( ${#matches[@]} == 0 )); then
        tlog_error "$tag" "No SourceForge artifact matched: %s" "$artifact_regex"

        return 5
    fi

    if (( ${#matches[@]} > 1 )); then
        tlog_error "$tag" "Multiple SourceForge artifacts matched: %s" "$artifact_regex"
        printf '%s\n' "${matches[@]}" >&2

        return 6
    fi

    printf '%s\n' "${matches[0]}"
}

##
# sourceforge_find_release
#
# Finds one artifact in the latest matching SourceForge release directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   project - SourceForge project name.
#   release_dir - Project-relative release directory.
#   version_regex - Extended regular expression matched against version directories.
#   artifact_regex - Extended regular expression matched against artifact filenames.
#
# Output:
#   Prints the matching artifact download URL to standard output.
#
# Return:
#   0 - Exactly one artifact was found in the latest matching version.
#   1 - The supplied arguments are invalid.
#   2 - The release directory could not be accessed.
#   3 - No version directory matched the version pattern.
#   4 - The selected version directory could not be accessed.
#   5 - No artifact matched the artifact pattern.
#   6 - Multiple artifacts matched the artifact pattern.
#
sourceforge_find_release() {
    local canonical_id="${1:-}"
    local project="${2:-}"
    local release_dir="${3:-}"
    local version_regex="${4:-}"
    local artifact_regex="${5:-}"
    local tag="external"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 5 )) ||
        [[ -z "$canonical_id" || -z "$project" || -z "$release_dir" ||
            -z "$version_regex" || -z "$artifact_regex" ]]; then
        tlog_error "$tag" "Invalid SourceForge release arguments"

        return 1
    fi

    release_dir="${release_dir#/}"
    release_dir="${release_dir%/}"

    if [[ -z "$release_dir" ]]; then
        tlog_error "$tag" "SourceForge release directory must not be empty"

        return 1
    fi

    local release_url="https://sourceforge.net/projects/$project/files/$release_dir"
    local release_path="/projects/$project/files/$release_dir/"
    local version

    local status

    if version="$(__sourceforge_find_latest_version \
        "$canonical_id" "$release_url/" "$release_path" "$version_regex")"; then
        :
    else
        status=$?

        return "$status"
    fi

    tlog_info "$tag" "Latest SourceForge version: %s" "$version"

    __sourceforge_find_artifact \
        "$canonical_id" "$release_url/$version" "$artifact_regex"
}
