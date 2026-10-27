#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GIT_PULL_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GIT_PULL_UPGRADE_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/registry.sh"

__git_clone_path() {
    local canonical_id="$1"
    local tag="$2"
    local clone_path

    if ! load_registry "$canonical_id" || ! clone_path="$(get_registry "INSTALL_PATH")"; then
        tlog_error "$tag" "Installation path is not recorded in the registry"

        return 1
    fi

    if [[ ! -d "$clone_path/.git" ]]; then
        tlog_error "$tag" "Installation path is not a git clone: %s" "$clone_path"

        return 1
    fi

    printf '%s\n' "$clone_path"
}

##
# git_pull_upgrade <canonical_id> [previous_name]
#
# Fast-forwards the git clone recorded in the registry INSTALL_PATH to the latest
# commit of its branch on origin with git pull --ff-only, then runs git gc. The
# pull also works on shallow clones; their history grows by the new commits. The
# upgrade is refused when tracked files have local edits, and the pull refuses
# when local commits or a rewritten upstream branch prevent a fast-forward. File
# mode changes (install scripts mark files executable) are ignored, and
# untracked files are kept.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging and registry.
#   previous_name - Optional name of a variable that receives the commit checked
#       out before the upgrade, for git_restore_commit.
#
# Return:
#   1 - The clone is missing, has local edits, or could not be fast-forwarded.
#
git_pull_upgrade() {
    local canonical_id="$1"
    local tag="git-upgrade:$canonical_id"
    local clone_path
    local branch
    local head_commit
    local changes

    clone_path="$(__git_clone_path "$canonical_id" "$tag")" || return 1

    if ! head_commit="$(git -C "$clone_path" rev-parse HEAD)" ||
        ! branch="$(git -C "$clone_path" symbolic-ref --short HEAD)"; then
        tlog_error "$tag" "Failed to inspect the git clone: %s" "$clone_path"

        return 1
    fi

    if ! changes="$(git -C "$clone_path" -c core.fileMode=false status --porcelain --untracked-files=no)"; then
        tlog_error "$tag" "Failed to check the git clone for local changes: %s" "$clone_path"

        return 1
    fi

    if [[ -n "$changes" ]]; then
        tlog_error "$tag" "Local changes in %s block the upgrade; stash or revert them first" "$clone_path"

        return 1
    fi

    if (( $# > 1 )); then
        local -n previous_ref="$2"
        previous_ref="$head_commit"
    fi

    # core.fileMode=false keeps executable bits set by install from counting as
    # local changes that would stop the pull.
    tlog_info "$tag" "Pulling branch %s into %s" "$branch" "$clone_path"
    if ! GIT_TERMINAL_PROMPT=0 git -C "$clone_path" -c core.fileMode=false pull --ff-only origin "$branch"; then
        tlog_error "$tag" "Failed to fast-forward branch %s; local commits or a rewritten upstream branch need manual handling" "$branch"

        return 1
    fi

    # The previous commit stays reachable as an ancestor, so gc keeps it for git_restore_commit.
    if ! git -C "$clone_path" gc --quiet; then
        tlog_warn "$tag" "git gc failed in: %s" "$clone_path"
    fi

    tlog_info "$tag" "Updated %s to %s" "${head_commit:0:12}" "$(git -C "$clone_path" rev-parse --short=12 HEAD)"
}

##
# git_restore_commit <canonical_id> <commit>
#
# Checks out a previous commit in the git clone recorded in the registry
# INSTALL_PATH, undoing git_pull_upgrade after a later upgrade step failed.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging and registry.
#   commit - Commit to restore, as returned by git_pull_upgrade.
#
# Return:
#   1 - The clone is missing or the commit could not be checked out.
#
git_restore_commit() {
    local canonical_id="$1"
    local commit="$2"
    local tag="git-upgrade:$canonical_id"
    local clone_path

    clone_path="$(__git_clone_path "$canonical_id" "$tag")" || return 1

    tlog_warn "$tag" "Restoring previous commit %s" "${commit:0:12}"
    if ! git -C "$clone_path" reset --quiet --hard "$commit"; then
        tlog_error "$tag" "Failed to restore commit %s in: %s" "$commit" "$clone_path"

        return 1
    fi
}
