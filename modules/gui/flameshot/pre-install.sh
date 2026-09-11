#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/github.sh"
source "${LIB_INSTALLER}/distro.sh"
source "${LIB_INSTALLER}/downloader.sh"
source "${LIB_INSTALLER}/extractor.sh"
source "${LIB_INSTALLER}/state.sh"

ubuntu_version="$(get_ubuntu_version)" || exit $?
regex="ubuntu-${ubuntu_version//./\\.}.?amd64\\.zip$"
tag="pre-install:$CANONICAL_ID"

# Download zip file
if ! zip_file="$(mktemp --suffix=.zip)"; then
    tlog_error "$tag" "Failed to create temporary zip file"

    exit 1
fi
url="$(github_find_release "$CANONICAL_ID" "flameshot-org" "flameshot" "$regex")" || exit $?
download_file "$CANONICAL_ID" "$url" "$zip_file" || exit $?

# Extract and find the .deb file
if ! extract_dir="$(mktemp -d)"; then
    tlog_error "$tag" "Fail to create temporary folder"

    exit 1
fi
extract_archive "$CANONICAL_ID" "zip" "$zip_file" "$extract_dir" || {
    rm -f -- "$zip_file" || true
    rm -rf -- "$extract_dir" || true

    exit 1
}
deb_file="$(find "$extract_dir" -name "*.deb" -print -quit)" || {
    tlog_error "$tag" "Fail to find .deb file from %s zip file" "$zip_file"
    rm -f -- "$zip_file" || true
    rm -rf -- "$extract_dir" || true

    exit 1
}
if [[ -z "$deb_file" ]]; then
    tlog_error "$tag" "No .deb file found in extracted %s zip file" "$zip_file"
    rm -f -- "$zip_file" || true
    rm -rf -- "$extract_dir" || true

    exit 1
fi

# Prepare .deb file for state management
if ! rm -f -- "$zip_file"; then
    tlog_error "$tag" "Fail to remove temporary zip file %s" "$zip_file"
    rm -rf -- "$extract_dir" || true

    exit 1
fi
if ! state_file="$(mktemp --suffix=.deb)"; then
    tlog_error "$tag" "Fail to create temporary deb file"
    rm -rf -- "$extract_dir" || true

    exit 1
fi
if ! mv "$deb_file" "$state_file"; then
    tlog_error "$tag" "Failed to move %s to %s" "$deb_file" "$state"
    rm -rf -- "$extract_dir" || true
    rm -f -- "$state_file" || true

    exit 1
fi
if ! rm -rf -- "$extract_dir"; then
    tlog_error "$tag" "Fail to remove temporary extract dir %s" "$extract_dir"
    rm -rf -- "$state_file" || true

    exit 1
fi

set_state "DEB_FILE" "$state_file" || exit $?
save_states "$CANONICAL_ID"
