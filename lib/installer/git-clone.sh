#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GIT_CLONE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GIT_CLONE_LOADED=1

source "$LIB_COMMON/common.sh"

__validate_git_clone_path() {
    local tag="$1"
    local clone_path="$2"
    local file

    shift 2

    if [[ ! -d "$clone_path" ]]; then
        tlog_error "$tag" "Target exists but is not a directory: %s" "$clone_path"

        return 1
    fi

    if [[ -z "$(find "$clone_path" -mindepth 1 -print -quit)" ]]; then
        # empty directory can proceed
        return 0
    fi

    if [[ ! -d "$clone_path/.git" || ! -f "$clone_path/.git/config" ]]; then
        tlog_error "$tag" "Target exists but is not a git repository: %s" "$clone_path"

        return 1
    fi

    for file in "$@"; do
        if [[ -f "$clone_path/$file" && ! -L "$clone_path/$file" ]]; then
            continue
        fi

        tlog_error "$tag" "Broken Git repository; missing regular file: %s" "$file"

        return 1
    done

    return 0
}

##
# git_clone <canonical_id> <git_url> <clone_path> [required_file]... [-- <git args...>]
#
# Shallow-clones a Git repository, or accepts an existing clone that contains the required files.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging.
#   git_url - Repository URL.
#   clone_path - Clone destination directory; must be missing, empty, or an existing clone.
#   required_file - File, relative to clone_path, that an existing clone must contain.
#   git args... - Additional git clone arguments passed as-is, such as --branch <name>.
#
# Return:
#   1 - The destination is invalid or cloning failed.
#
git_clone() {
    local canonical_id="$1"
    local git_url="$2"
    local clone_path="$3"
    local tag="git-clone:$canonical_id"
    local -a required_files=()
    local -a git_args=()

    shift 3

    while (( $# > 0 )); do
        # Everything after -- belongs to git clone.
        if [[ "$1" == "--" ]]; then
            shift
            git_args=("$@")
            break
        fi

        required_files+=("$1")
        shift
    done

    tlog_info "$tag" "Checking %s directory before cloning" "$clone_path"
    if [[ -e "$clone_path" ]]; then
        __validate_git_clone_path "$tag" "$clone_path" "${required_files[@]}" || return $?
        if [[ -d "$clone_path/.git" ]]; then
            tlog_warn "$tag" "Skipping clone; %s is already a valid Git repository" "$clone_path"

            return 0
        fi
    fi

    tlog_info "$tag" "Cloning %s into %s" "$git_url" "$clone_path"
    if ! mkdir -p "$clone_path"; then
        tlog_error "$tag" "Failed to create directory: %s" "$clone_path"

        return 1
    fi

    if git clone --depth 1 "${git_args[@]}" "$git_url" "$clone_path"; then
        return 0
    fi

    tlog_error "$tag" "Failed to clone %s into %s; target may not be empty" "$git_url" "$clone_path"

    return 1
}