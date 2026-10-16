#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_HOME_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_HOME_LOADED=1

source "$LIB_COMMON/common.sh"

##
# __valid_home_path <path>
#
# Succeeds for a non-empty relative path without "." or ".." segments, glob
# characters, or control characters.
#
__valid_home_path() {
    local path="$1"

    if [[ -z "$path" || "$path" == /* || "$path" == *[\*\?\[\]]* ||
        "$path" == *$'\n'* || "$path" == *$'\r'* ]]; then
        return 1
    fi

    if [[ "/$path/" == */../* || "/$path/" == */./* || "/$path/" == *//* ]]; then
        return 1
    fi

    return 0
}

##
# purge_home_paths
#
# Deletes lingering user files for each relative path from these locations:
# $HOME/.local/<path>, $HOME/.local/share/<path>, $HOME/.local/state/<path>,
# $HOME/.config/<path>, $HOME/.cache/<path>, and $HOME/.<path>. Only acts when
# PURGE=true. Missing locations are skipped, symlinks are removed without being
# followed, and targets whose parent resolves outside $HOME are refused. All
# arguments are validated before anything is deleted.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   path - One or more relative paths, such as "kitty" or "JetBrains/IntelliJ".
#
# Return:
#   1 - Validation failed or at least one deletion failed.
#
purge_home_paths() {
    local canonical_id="${1:-}"
    local tag="purge-home"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID and at least one path are required"

        return 1
    fi

    shift

    local path
    local normalized
    local target
    local parent
    local home_real
    local failed=0
    local -a paths=()
    local -a targets=()

    if [[ "${HOME:-}" != /* || "$HOME" == "/" ]]; then
        tlog_error "$tag" "HOME must be an absolute path other than /"

        return 1
    fi

    for path in "$@"; do
        normalized="$path"

        while [[ "$normalized" == */ ]]; do
            normalized="${normalized%/}"
        done

        if ! __valid_home_path "$normalized"; then
            tlog_error "$tag" "Invalid home path (must be relative, without .., ./ or globs): %s" "$path"

            return 1
        fi

        paths+=("$normalized")
    done

    if [[ "${PURGE:-false}" != "true" ]]; then
        tlog_info "$tag" "Skipping home cleanup (use mp purge to remove user files)"

        return 0
    fi

    if ! home_real="$(realpath -- "$HOME")"; then
        tlog_error "$tag" "Unable to resolve HOME"

        return 1
    fi

    for path in "${paths[@]}"; do
        targets+=(
            "$HOME/.local/$path"
            "$HOME/.local/share/$path"
            "$HOME/.local/state/$path"
            "$HOME/.config/$path"
            "$HOME/.cache/$path"
            "$HOME/.$path"
        )
    done

    for target in "${targets[@]}"; do
        case "$target" in
            "$HOME/.local" | "$HOME/.config" | "$HOME/.cache")
                continue
                ;;
        esac

        if [[ ! -e "$target" && ! -L "$target" ]]; then
            continue
        fi

        if ! parent="$(realpath -m -- "${target%/*}")" ||
            [[ "$parent" != "$home_real" && "$parent" != "$home_real"/* ]]; then
            tlog_error "$tag" "Refusing to remove a path that resolves outside HOME: %s" "$target"
            failed=1

            continue
        fi

        tlog_info "$tag" "Removing %s" "$target"

        if ! rm -rf -- "$target"; then
            tlog_error "$tag" "Failed to remove %s" "$target"
            failed=1
        fi
    done

    return "$failed"
}
