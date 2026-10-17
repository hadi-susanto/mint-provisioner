#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_DESKTOP_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_DESKTOP_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/desktop-integration.sh"

##
# remove_desktop_entry
#
# Removes a desktop entry and its icons created by install_desktop_entry, then
# refreshes the icon and desktop caches when anything was deleted. Missing files
# are not an error.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   desktop_id - Desktop entry file name without the .desktop extension; also
#                the installed icon name.
#
# Return:
#   1 - Validation failed or a file could not be removed.
#
remove_desktop_entry() {
    local canonical_id="${1:-}"
    local desktop_id="${2:-}"
    local tag="remove-desktop"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$desktop_id" ]]; then
        tlog_error "$tag" "A canonical ID and desktop ID are required"

        return 1
    fi

    if [[ ! "$desktop_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || "$desktop_id" == *..* ]]; then
        tlog_error "$tag" "Invalid desktop ID: %s" "$desktop_id"

        return 1
    fi

    local desktop_file
    local icon_dir
    local file
    local entry_removed=0
    local icon_removed=0
    local -a files=()

    desktop_file="$(desktop_entry_path "$desktop_id")"
    icon_dir="$(desktop_icon_theme_dir)"

    if [[ -e "$desktop_file" || -L "$desktop_file" ]]; then
        files+=("$desktop_file")
    fi

    for file in "$icon_dir"/*/apps/"$desktop_id".*; do
        if [[ -f "$file" || -L "$file" ]]; then
            files+=("$file")
        fi
    done

    if (( ${#files[@]} == 0 )); then
        tlog_info "$tag" "No desktop entry or icons found for %s" "$desktop_id"

        return 0
    fi

    for file in "${files[@]}"; do
        tlog_info "$tag" "Removing %s" "$file"

        if ! sudo rm -f -- "$file"; then
            tlog_error "$tag" "Failed to remove %s" "$file"

            return 1
        fi

        if [[ "$file" == "$desktop_file" ]]; then
            entry_removed=1
        else
            icon_removed=1
        fi
    done

    if (( icon_removed )) && command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if ! sudo gtk-update-icon-cache -f -t "$icon_dir"; then
            tlog_warn "$tag" "Failed to refresh the icon cache"
        fi
    fi

    if (( entry_removed )) && command -v update-desktop-database >/dev/null 2>&1; then
        if ! sudo update-desktop-database "$(desktop_application_dir)"; then
            tlog_warn "$tag" "Failed to refresh the desktop application database"
        fi
    fi

    return 0
}
