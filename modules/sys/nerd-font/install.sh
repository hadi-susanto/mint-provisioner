#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/installer.sh"

tag="install:$CANONICAL_ID"
installed_list=""
failed_list=""
installed_fonts=()
failed_fonts=()

load_states "$CANONICAL_ID" || exit 1
archive_dir="$(get_state "FONT_ARCHIVES")" || exit 1

if [[ ! -d "$archive_dir" ]]; then
    tlog_error "$tag" "Font archive directory not found: %s" "$archive_dir"

    exit 2
fi

for archive_file in "$archive_dir"/*; do
    if [[ ! -f "$archive_file" ]]; then
        continue
    fi

    font_name="${archive_file##*/}"
    font_name="${font_name%.tar.xz}"

    if install_font "$font_name" "$archive_file"; then
        installed_fonts+=("$font_name")
    else
        failed_fonts+=("$font_name")

        tlog_error "$tag" "Failed to install Nerd Font family: %s" "$font_name"
    fi
done

if (( ${#installed_fonts[@]} > 0 )); then
    refresh_font_cache

    printf -v installed_list '%s, ' "${installed_fonts[@]}"
    installed_list="${installed_list%, }"
    add_message "$CANONICAL_ID" "info" "Installed font(s): $installed_list"
fi

if (( ${#failed_fonts[@]} > 0 )); then
    printf -v failed_list '%s, ' "${failed_fonts[@]}"
    failed_list="${failed_list%, }"
    tlog_warn "$tag" "Installed: $installed_list"
    tlog_warn "$tag" "Failed to install: $failed_list"
    add_message "$CANONICAL_ID" "error" "Failed to install font(s): $failed_list"

    exit 1
fi

tlog_info "$tag" "All Nerd Font families installed successfully"
