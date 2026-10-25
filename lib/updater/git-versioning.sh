#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GIT_VERSIONING_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GIT_VERSIONING_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/registry.sh"

##
# git_commits <canonical_id> <commits_name>
#
# Reads the commit checked out in the module's clone (registry INSTALL_PATH)
# and the latest commit of the same branch on its origin remote. Nothing is
# fetched or written to the clone.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   commits_name - Name of the associative array that receives full commit
#       hashes as [INSTALLED] and [LATEST].
#
# Return:
#   1 - No registry or INSTALL_PATH was recorded.
#   2 - A git query failed.
#
git_commits() {
    local canonical_id="$1"
    local -n commits_ref="$2"
    local tag="git-versioning:$canonical_id"
    local status=0
    local clone_path
    local branch
    local remote_url
    local local_commit
    local remote_line

    commits_ref=()

    load_registry "$canonical_id" silent || status=$?
    if (( status != 0 )); then
        return "$status"
    fi

    if ! has_registry "INSTALL_PATH"; then
        return 1
    fi

    clone_path="$(get_registry "INSTALL_PATH")" || return 1

    if ! local_commit="$(git -C "$clone_path" rev-parse HEAD 2>/dev/null)" ||
        ! branch="$(git -C "$clone_path" symbolic-ref --short HEAD 2>/dev/null)" ||
        ! remote_url="$(git -C "$clone_path" remote get-url origin 2>/dev/null)"; then
        tlog_error "$tag" "Failed to inspect the git clone: %s" "$clone_path"

        return 2
    fi

    if ! remote_line="$(GIT_TERMINAL_PROMPT=0 git ls-remote "$remote_url" "refs/heads/$branch" 2>/dev/null)" ||
        [[ -z "$remote_line" ]]; then
        tlog_error "$tag" "Failed to query %s branch %s" "$remote_url" "$branch"

        return 2
    fi

    commits_ref[INSTALLED]="$local_commit"
    commits_ref[LATEST]="${remote_line%%[[:space:]]*}"
}
