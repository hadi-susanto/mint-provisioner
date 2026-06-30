#!/usr/bin/env bash

#
# Pre-install phase for Flameshot.
#
# Actions:
#   1. Create a temporary file to hold the package.
#   2. Resolve the latest Ubuntu .deb release from GitHub.
#   3. Persist the temporary file path into the module state file.
#   4. Download the package into the temporary file.
#
# Environment:
#   FLAMESHOT_REGEX
#       Optional regular expression used to locate the release asset.
#       When set, the default Ubuntu-version-specific pattern is ignored.
#
# State:
#   Writes the download path to:
#       ${STATE_DIR}/flameshot.path
#
# Exit codes:
#   1 - Failed to create temporary file
#   2 - Failed to resolve latest release
#   3 - Failed to create state file
#   4 - Failed to download package
#

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/distro.sh"

MODULE="flameshot"
STATE_FILE="$STATE_DIR/flameshot.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_temp_file="$(mktemp)"; then
    log_error "[$MODULE] Failed to create temporary file"
    exit 1
fi

ubuntu_version="$(get_ubuntu_version)"

if [[ -z "${FLAMESHOT_REGEX:-}" ]]; then
    # Matches ubuntu-[version][any-single-char]amd64.zip or .deb
    # Example: ubuntu-24.04.amd64.deb or ubuntu-24.04-amd64.zip
    FLAMESHOT_REGEX="ubuntu-${ubuntu_version//./\\.}.?amd64\\.(zip|deb)$"
fi

log_info "[$MODULE] Finding github latest release using regex: $FLAMESHOT_REGEX"

if ! url="$(
    github_find_release \
        "$MODULE" \
        flameshot-org \
        flameshot \
        "$FLAMESHOT_REGEX"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    log_error "[$MODULE] No release asset matched regex: $FLAMESHOT_REGEX"
    log_error "[$MODULE] This may indicate that Flameshot no longer publishes packages for Ubuntu $ubuntu_version."
    log_error "[$MODULE] Please contact the framework maintainer to update the module."
    log_error "[$MODULE] Alternatively, set FLAMESHOT_REGEX to manually select an asset."

    rm -f "$download_temp_file"

    exit 2
fi

if ! download_file "$MODULE" "$url" "$download_temp_file"; then
    log_error "[$MODULE] Download failed"

    rm -f "$download_temp_file"

    exit 3
fi

if [[ "$url" == *.zip ]]; then
    log_info "[$MODULE] Payload is a ZIP file, extracting to find .deb"
    
    extract_dir="$(mktemp -d)"
    if ! unzip -q "$download_temp_file" -d "$extract_dir"; then
        log_error "[$MODULE] Failed to extract ZIP file"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file"
        exit 4
    fi

    # Find the .deb file in the extracted directory
    deb_file=$(find "$extract_dir" -name "*.deb" -print -quit)
    
    if [[ -z "$deb_file" ]]; then
        log_error "[$MODULE] No .deb file found in extracted ZIP"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file"
        exit 5
    fi

    log_info "[$MODULE] Found .deb in ZIP: $deb_file"
    
    # Move the .deb to a permanent temporary location
    final_deb_file="$(mktemp --suffix=.deb)"
    mv "$deb_file" "$final_deb_file"
    
    # Cleanup
    rm -rf "$extract_dir"
    rm -f "$download_temp_file"
    
    download_file="$final_deb_file"
else
    # It was already a .deb, just rename the temp file to have .deb suffix for clarity
    final_deb_file="$(mktemp --suffix=.deb)"
    mv "$download_temp_file" "$final_deb_file"
    download_file="$final_deb_file"
fi

log_info "[$MODULE] Creating state file: $STATE_FILE"

if ! printf '%s\n' "$download_file" > "$STATE_FILE"; then
    log_error "[$MODULE] Failed to create state file"

    rm -f "$download_file"

    exit 6
fi

log_info "[$MODULE] Download completed successfully"
