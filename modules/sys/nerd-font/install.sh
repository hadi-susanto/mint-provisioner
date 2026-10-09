#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/installer.sh"

main() {
    local canonical_id="$1"
    local archive_dir
    local archive_file
    local font_name
    local installed_list=""
    local failed_list=""
    local -a installed_fonts=()
    local -a failed_fonts=()

    load_states "$canonical_id" || return 1
    archive_dir="$(get_state "FONT_ARCHIVES")" || return 1

    if [[ ! -d "$archive_dir" ]]; then
        tlog_error "install:$canonical_id" "Font archive directory not found: %s" "$archive_dir"

        return 2
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

            tlog_error "install:$canonical_id" "Failed to install Nerd Font family: %s" "$font_name"
        fi
    done

    if (( ${#installed_fonts[@]} > 0 )); then
        refresh_font_cache

        printf -v installed_list '%s, ' "${installed_fonts[@]}"
        installed_list="${installed_list%, }"
        add_message "$canonical_id" "info" "Installed font(s): $installed_list"
    fi

    if (( ${#failed_fonts[@]} > 0 )); then
        printf -v failed_list '%s, ' "${failed_fonts[@]}"
        failed_list="${failed_list%, }"
        tlog_warn "install:$canonical_id" "Installed: $installed_list"
        tlog_warn "install:$canonical_id" "Failed to install: $failed_list"
        add_message "$canonical_id" "error" "Failed to install font(s): $failed_list"

        return 1
    fi

    tlog_info "install:$canonical_id" "All Nerd Font families installed successfully"
}

main "$CANONICAL_ID"
