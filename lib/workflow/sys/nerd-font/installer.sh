#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_NERD_FONT_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_NERD_FONT_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"

readonly NERD_FONT_INSTALL_ROOT="/usr/local/share/fonts/nerd-font"

##
# font_installed <font_name>
#
# Tests whether a Nerd Font family is installed under NERD_FONT_INSTALL_ROOT.
#
# Parameters:
#   font_name - Font family name.
#
# Return:
#   0 - The family directory contains at least one usable TTF or OTF file.
#   1 - The family is not installed.
#   2 - Arguments are invalid or filesystem inspection failed.
#
font_installed() {
    local font_name="${1:-}"
    local font_dir
    local font_file

    if (( $# != 1 )) || [[ -z "$font_name" ]]; then
        tlog_error "nerd-font:$CANONICAL_ID" "A font name is required"

        return 2
    fi

    font_dir="$NERD_FONT_INSTALL_ROOT/$font_name"

    if [[ ! -d "$font_dir" ]]; then
        return 1
    fi

    if ! font_file="$(
        find "$font_dir" \
            -type f \
            \( -iname '*.ttf' -o -iname '*.otf' \) \
            -print \
            -quit 2>/dev/null
    )"; then
        return 2
    fi

    [[ -n "$font_file" ]]
}

##
# install_font <font_name> <archive_file>
#
# Extracts a downloaded `.tar.xz` Nerd Font archive into its family directory
# under NERD_FONT_INSTALL_ROOT.
#
# Parameters:
#   font_name - Font family name.
#   archive_file - Path to the downloaded `.tar.xz` archive.
#
# Return:
#   1 - Required arguments are missing or the archive file does not exist.
#   2 - The family directory could not be created.
#   3 - The archive could not be extracted.
#   4 - The extracted family contains no usable font files.
#
install_font() {
    local font_name="${1:-}"
    local archive_file="${2:-}"
    local font_dir
    local tag="nerd-font:$CANONICAL_ID"

    if (( $# != 2 )) || [[ -z "$font_name" || -z "$archive_file" ]]; then
        tlog_error "$tag" "A font name and archive file are required"

        return 1
    fi

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Downloaded archive was not found for %s: %s" \
            "$font_name" "$archive_file"

        return 1
    fi

    font_dir="$NERD_FONT_INSTALL_ROOT/$font_name"
    tlog_info "$tag" "Installing %s to %s" "$font_name" "$font_dir"

    if ! sudo mkdir -p -- "$font_dir"; then
        tlog_error "$tag" "Failed to create font directory: %s" "$font_dir"

        return 2
    fi

    if ! sudo tar -xJf "$archive_file" -C "$font_dir"; then
        tlog_error "$tag" "Failed to extract Nerd Font family: %s" "$font_name"

        return 3
    fi

    if font_installed "$font_name"; then
        return 0
    fi

    tlog_error "$tag" "Installed family contains no usable font files: %s" "$font_name"

    return 4
}

##
# refresh_font_cache
#
# Refreshes the system font cache for NERD_FONT_INSTALL_ROOT. A failure is
# logged as a warning because it does not invalidate a completed installation.
#
refresh_font_cache() {
    local tag="nerd-font:$CANONICAL_ID"

    tlog_info "$tag" "Refreshing the system font cache"

    if ! sudo fc-cache -fv "$NERD_FONT_INSTALL_ROOT"; then
        tlog_warn "$tag" \
            "Failed to refresh the font cache; run 'sudo fc-cache -fv %s' manually" \
            "$NERD_FONT_INSTALL_ROOT"
    fi
}
