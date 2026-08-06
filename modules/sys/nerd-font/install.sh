#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/messages.sh"
source "$MP_MODULES/$CANONICAL_ID/font.sh"

readonly SYSTEM_FONT_DIR="/usr/local/share/fonts/nerd-font"

__install_font() {
    local canonical_id="$1"
    local install_root="$2"
    local font_family="$3"
    local archive_file="$4"
    local font_dir="$install_root/$font_family"
    local tag="install:$canonical_id"
    local status

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Downloaded archive was not found for %s: %s" \
            "$font_family" "$archive_file"

        return 2
    fi

    tlog_info "$tag" "Installing %s to %s" "$font_family" "$font_dir"

    if ! sudo mkdir -p -- "$font_dir"; then
        tlog_error "$tag" "Failed to create font directory: %s" "$font_dir"

        return 3
    fi

    if ! sudo unzip -o "$archive_file" -d "$font_dir"; then
        tlog_error "$tag" "Failed to extract Nerd Font family: %s" "$font_family"

        return 4
    fi

    if nerd_font_family_installed "$install_root" "$font_family"; then
        return 0
    else
        status=$?
    fi

    tlog_error "$tag" "Installed family contains no usable font files: %s" \
        "$font_family"

    if (( status > 1 )); then
        return "$status"
    fi

    return 5
}

main() {
    local canonical_id="$1"
    local install_root="$2"
    local raw_families
    local archive_file
    local font_family
    local index
    local -a font_families=()
    local -a installed_fonts=()
    local -a failed_fonts=()
    local installed_list=""
    local failed_list=""

    load_states "$canonical_id" || return 1
    raw_families="$(get_state "FONT_FAMILIES")" || return 1
    nerd_font_parse_families "$raw_families" font_families || return $?

    for (( index = 0; index < ${#font_families[@]}; index += 1 )); do
        font_family="${font_families[$index]}"

        if archive_file="$(get_state "DOWNLOAD_FILE_$index")" &&
            __install_font "$canonical_id" "$install_root" "$font_family" "$archive_file"; then
            installed_fonts+=("$font_family")

            continue
        fi

        failed_fonts+=("$font_family")

        tlog_error \
            "install:$canonical_id" "Failed to install Nerd Font family: %s" "$font_family"
    done

    if (( ${#installed_fonts[@]} > 0 )); then
        tlog_info "install:$canonical_id" "Refreshing the system font cache"

        if ! sudo fc-cache -fv "$install_root"; then
            tlog_warn \
                "install:$canonical_id" \
                "Failed to refresh the font cache; run 'sudo fc-cache -fv %s' manually" \
                "$install_root"
        fi


        printf -v installed_list '%s, ' "${installed_fonts[@]}"
        installed_list="${installed_list%, }"
        add_message "$canonical_id" "info" "Installed font(s): $installed_list"
    fi

    if (( ${#failed_fonts[@]} > 0 )); then
        printf -v failed_list '%s, ' "${failed_fonts[@]}"
        failed_list="${failed_list%, }"
        tlog_warn \
            "install:$canonical_id" "Installed: $installed_list"
        tlog_warn \
            "install:$canonical_id" "Fail to install: $failed_list"
        add_message "$canonical_id" "error" "Failed to install font(s): $failed_list"

        return 1
    fi

    tlog_info \
        "install:$canonical_id" "All Nerd Font families installed successfully"
}

main "$CANONICAL_ID" "$SYSTEM_FONT_DIR"
