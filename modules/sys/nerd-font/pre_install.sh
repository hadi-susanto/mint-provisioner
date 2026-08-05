#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"
source "$MP_MODULES/$CANONICAL_ID/font.sh"

__cleanup_files() {
    if (( $# > 0 )); then
        rm -f -- "$@" || true
    fi
}

__download_font_archive() {
    local canonical_id="$1"
    local font_family="$2"
    local tag="pre-install:$canonical_id"
    local archive_file
    local regex
    local url

    regex="${font_family//./[.]}"
    regex="${regex//+/[+]}\.zip$"

    if ! archive_file="$(mktemp --suffix=.zip)"; then
        tlog_error "$tag" "Failed to create a temporary archive for: %s" \
            "$font_family"

        return 1
    fi

    tlog_info "$tag" "Resolving the latest release for: %s" "$font_family"
    if ! url="$(
        github_find_release "$canonical_id" ryanoasis nerd-fonts "$regex"
    )"; then
        tlog_error "$tag" "Failed to resolve a release for: %s" "$font_family"
        rm -f -- "$archive_file"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$archive_file"; then
        tlog_error "$tag" "Failed to download Nerd Font family: %s" "$font_family"
        rm -f -- "$archive_file"

        return 3
    fi

    printf '%s\n' "$archive_file"
}

main() {
    local canonical_id="$1"
    local raw_families
    local normalized_families
    local archive_file
    local font_family
    local index
    local status
    local -a font_families=()
    local -a downloaded_files=()

    if ! nerd_font_resolve_selection \
        "${NERD_FONT_FAMILIES:-}" "${NERD_FONT_FAMILY:-}" raw_families; then
        tlog_error "pre-install:$canonical_id" \
            "Set NERD_FONT_FAMILIES or NERD_FONT_FAMILY to at least one font family"

        return 1
    fi

    nerd_font_parse_families "$raw_families" font_families || return $?
    nerd_font_join_families font_families normalized_families

    tlog_info "pre-install:$canonical_id" "Preparing Nerd Font families: %s" \
        "$normalized_families"

    for font_family in "${font_families[@]}"; do
        if archive_file="$(__download_font_archive "$canonical_id" "$font_family")"; then
            downloaded_files+=("$archive_file")
        else
            status=$?
            __cleanup_files "${downloaded_files[@]}"

            return "$status"
        fi
    done

    if ! set_state "FONT_FAMILIES" "$normalized_families"; then
        __cleanup_files "${downloaded_files[@]}"

        return 4
    fi

    for (( index = 0; index < ${#downloaded_files[@]}; index += 1 )); do
        if ! set_state "DOWNLOAD_FILE_$index" "${downloaded_files[$index]}"; then
            __cleanup_files "${downloaded_files[@]}"

            return 4
        fi
    done

    if ! save_states "$canonical_id"; then
        tlog_error "pre-install:$canonical_id" "Failed to save installation state"
        __cleanup_files "${downloaded_files[@]}"

        return 4
    fi

    tlog_info "pre-install:$canonical_id" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID"
