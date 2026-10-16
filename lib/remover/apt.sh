#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_APT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_APT_LOADED=1

source "$LIB_COMMON/common.sh"

##
# remove_ppa
#
# Removes a Launchpad PPA and refreshes the package index. Only acts when
# PURGE=true; otherwise the repository is kept.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   repository - Launchpad PPA identifier that was added.
#
# Return:
#   1 - Validation, repository removal, or index refresh failed.
#
remove_ppa() {
    local canonical_id="${1:-}"
    local repository="${2:-}"
    local tag="remove-ppa"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$repository" ]]; then
        tlog_error "$tag" "A canonical ID and PPA repository are required"

        return 1
    fi

    if [[ "${PURGE:-false}" != "true" ]]; then
        tlog_info "$tag" "Keeping PPA repository (use mp purge to remove it): %s" "$repository"

        return 0
    fi

    tlog_info "$tag" "Removing PPA repository: %s" "$repository"

    if ! sudo add-apt-repository -r -y "$repository"; then
        tlog_error "$tag" "Failed to remove PPA repository: %s" "$repository"

        return 1
    fi

    tlog_info "$tag" "Updating package lists"

    if ! sudo apt-get update; then
        tlog_error "$tag" "Failed to update package lists"

        return 1
    fi

    return 0
}

##
# remove_apt_repository
#
# Removes the signing key and deb822 source file created by install_asc_key,
# then refreshes the package index. Only acts when PURGE=true; otherwise the
# files are kept.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and the default filename.
#   filename - Optional keyring and source filename without an extension; must
#              match the value passed to install_asc_key.
#
# Return:
#   1 - Validation, file deletion, or index refresh failed.
#
remove_apt_repository() {
    local canonical_id="${1:-}"
    local filename="${2:-$canonical_id}"
    local tag="remove-apt"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 1 || $# > 2 )) || [[ -z "$canonical_id" || -z "$filename" ]]; then
        tlog_error "$tag" "Invalid APT repository arguments"

        return 1
    fi

    local normalized_filename="${filename//\//_}"
    local source_file="/etc/apt/sources.list.d/$normalized_filename.sources"
    local keyring_file="/etc/apt/keyrings/$normalized_filename.gpg"
    local file
    local removed=0

    if [[ "$normalized_filename" == .* || "$normalized_filename" == *..* ||
        ! "$normalized_filename" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        tlog_error "$tag" "Invalid APT repository filename: %s" "$filename"

        return 1
    fi

    if [[ "${PURGE:-false}" != "true" ]]; then
        tlog_info "$tag" "Keeping APT repository files (use mp purge to remove them): %s" \
            "$normalized_filename"

        return 0
    fi

    for file in "$source_file" "$keyring_file"; do
        if [[ ! -e "$file" && ! -L "$file" ]]; then
            continue
        fi

        tlog_info "$tag" "Removing %s" "$file"

        if ! sudo rm -f "$file"; then
            tlog_error "$tag" "Failed to remove %s" "$file"

            return 1
        fi

        removed=1
    done

    if (( ! removed )); then
        tlog_info "$tag" "No APT repository files found for %s" "$normalized_filename"

        return 0
    fi

    tlog_info "$tag" "Updating package lists"

    if ! sudo apt-get update; then
        tlog_error "$tag" "Failed to update package lists"

        return 1
    fi

    return 0
}
