#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_FLAMESHOT_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_FLAMESHOT_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/extractor.sh"
source "$LIB_INSTALLER/state.sh"

##
# flameshot_download_deb <canonical_id>
#
# Downloads the Flameshot release zip for the running Ubuntu version, extracts
# its .deb package, and saves the package path in the DEB_FILE state with the
# release VERSION. Used by pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - The release could not be found, downloaded, verified, or unpacked.
#
flameshot_download_deb() {
    local canonical_id="$1"
    local tag="download:$canonical_id"
    local ubuntu_version
    local regex
    local zip_file
    local extract_dir
    local deb_file
    local state_file
    local -A flameshot_asset=()

    ubuntu_version="$(get_ubuntu_version)" || return $?
    regex="ubuntu-${ubuntu_version//./\\.}.?amd64\\.zip$"

    github_find_release_asset "$canonical_id" "flameshot-org" "flameshot" "$regex" flameshot_asset || return $?

    if ! zip_file="$(mktemp --suffix=.zip)"; then
        tlog_error "$tag" "Failed to create temporary zip file"

        return 1
    fi

    if ! download_file "$canonical_id" "${flameshot_asset[URL]}" "$zip_file" ||
        ! verify_sha256 "$canonical_id" "$zip_file" "${flameshot_asset[SHA256]}"; then
        rm -f -- "$zip_file" || true

        return 1
    fi

    if ! extract_dir="$(mktemp -d)"; then
        tlog_error "$tag" "Failed to create temporary folder"
        rm -f -- "$zip_file" || true

        return 1
    fi

    if ! extract_archive "$canonical_id" "zip" "$zip_file" "$extract_dir"; then
        rm -f -- "$zip_file" || true
        rm -rf -- "$extract_dir" || true

        return 1
    fi

    rm -f -- "$zip_file" || true

    deb_file="$(find "$extract_dir" -name "*.deb" -print -quit)" || deb_file=""
    if [[ -z "$deb_file" ]]; then
        tlog_error "$tag" "No .deb file found in the Flameshot release zip"
        rm -rf -- "$extract_dir" || true

        return 1
    fi

    if ! state_file="$(mktemp --suffix=.deb)"; then
        tlog_error "$tag" "Failed to create temporary deb file"
        rm -rf -- "$extract_dir" || true

        return 1
    fi

    if ! mv -- "$deb_file" "$state_file"; then
        tlog_error "$tag" "Failed to move %s to %s" "$deb_file" "$state_file"
        rm -rf -- "$extract_dir" || true
        rm -f -- "$state_file" || true

        return 1
    fi

    if ! rm -rf -- "$extract_dir"; then
        tlog_warn "$tag" "Failed to remove temporary extract dir %s" "$extract_dir"
    fi

    set_state "DEB_FILE" "$state_file" || return $?
    set_state "VERSION" "${flameshot_asset[VERSION]}" || return $?
    save_states "$canonical_id"
}
