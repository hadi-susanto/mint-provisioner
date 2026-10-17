#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_JETBRAINS_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_JETBRAINS_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_REMOVER/home.sh"

##
# purge_jetbrains_dirs
#
# Deletes the per-version configuration, cache, and data directories of one
# JetBrains product from ~/.config/JetBrains, ~/.cache/JetBrains, and
# ~/.local/share/JetBrains through purge_home_paths, so it only deletes when
# PURGE=true. The shared "JetBrains" root and other products are never touched.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   product_prefix - One or more directory name prefixes of the product, such
#                    as "PyCharm" or "IntelliJIdea" (matches PyCharm2025.1).
#
# Return:
#   1 - Validation failed or a deletion failed.
#
purge_jetbrains_dirs() {
    local canonical_id="${1:-}"
    local tag="purge-jetbrains"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID and at least one product prefix are required"

        return 1
    fi

    shift

    local prefix
    local root
    local dir
    local -A version_dirs=()

    for prefix in "$@"; do
        if [[ ! "$prefix" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
            tlog_error "$tag" "Invalid product prefix: %s" "$prefix"

            return 1
        fi
    done

    for root in "$HOME/.config/JetBrains" "$HOME/.cache/JetBrains" "$HOME/.local/share/JetBrains"; do
        for prefix in "$@"; do
            for dir in "$root/$prefix"*; do
                if [[ -d "$dir" ]]; then
                    version_dirs["JetBrains/${dir##*/}"]=1
                fi
            done
        done
    done

    if (( ${#version_dirs[@]} == 0 )); then
        tlog_info "$tag" "No JetBrains directories found for: %s" "$*"

        return 0
    fi

    purge_home_paths "$canonical_id" "${!version_dirs[@]}"
}
