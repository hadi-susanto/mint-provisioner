#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/installer.sh"

__download_font_archive() {
    local canonical_id="$1"
    local font_family="$2"
    local archive_file="$3"
    local tag="pre-install:$canonical_id"
    local regex
    local url

    regex="${font_family//./[.]}"
    regex="${regex//+/[+]}\.tar\.xz$"

    tlog_info "$tag" "Resolving the latest release for: %s" "$font_family"

    if ! url="$(github_find_release "$canonical_id" ryanoasis nerd-fonts "$regex")"; then
        tlog_error "$tag" "Failed to resolve a release for: %s" "$font_family"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$archive_file"; then
        tlog_error "$tag" "Failed to download Nerd Font family: %s" "$font_family"

        return 3
    fi
}

main() {
    local canonical_id="$1"
    local raw_families
    local font_family
    local archive_dir
    local archive_file
    local status
    local -a font_families=()

    load_states "$canonical_id" || return 1
    raw_families="$(get_state "FONT_FAMILIES")" || return 1
    nerd_font_parse_families "$raw_families" font_families || return $?

    if ! archive_dir="$(mktemp -d)"; then
        tlog_error "pre-install:$canonical_id" "Failed to create a temporary download directory"

        return 1
    fi

    for font_family in "${font_families[@]}"; do
        if font_installed "$font_family"; then
            tlog_info "pre-install:$canonical_id" \
                "Already installed, skipping download: %s" "$font_family"

            continue
        fi

        archive_file="$archive_dir/$font_family.tar.xz"

        if ! __download_font_archive "$canonical_id" "$font_family" "$archive_file"; then
            status=$?
            rm -rf -- "$archive_dir"

            return "$status"
        fi
    done

    if ! set_state "FONT_ARCHIVES" "$archive_dir"; then
        rm -rf -- "$archive_dir"

        return 1
    fi

    if ! save_states "$canonical_id"; then
        tlog_error "pre-install:$canonical_id" "Failed to save installation state"
        rm -rf -- "$archive_dir"

        return 1
    fi

    tlog_info "pre-install:$canonical_id" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID"
