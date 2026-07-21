#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/distro.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_temp_file="$(mktemp)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

ubuntu_version="$(get_ubuntu_version)"

if [[ -z "${FLAMESHOT_REGEX:-}" ]]; then
    # Matches ubuntu-[version][any-single-char]amd64.zip or .deb
    # Example: ubuntu-24.04.amd64.deb or ubuntu-24.04-amd64.zip
    FLAMESHOT_REGEX="ubuntu-${ubuntu_version//./\\.}.?amd64\\.(zip|deb)$"
fi

log_info "[$CANONICAL_ID] Finding github latest release using regex: $FLAMESHOT_REGEX"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        flameshot-org \
        flameshot \
        "$FLAMESHOT_REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    log_error "[$CANONICAL_ID] No release asset matched regex: $FLAMESHOT_REGEX"
    log_error "[$CANONICAL_ID] This may indicate that Flameshot no longer publishes packages for Ubuntu $ubuntu_version."
    log_error "[$CANONICAL_ID] Please contact the framework maintainer to update the module."
    log_error "[$CANONICAL_ID] Alternatively, set FLAMESHOT_REGEX to manually select an asset."

    rm -f "$download_temp_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_temp_file"; then
    log_error "[$CANONICAL_ID] Download failed"

    rm -f "$download_temp_file"

    exit 3
fi

if [[ "$url" == *.zip ]]; then
    log_info "[$CANONICAL_ID] Payload is a ZIP file, extracting to find .deb"
    
    if ! extract_dir="$(mktemp -d)"; then
        log_error "[$CANONICAL_ID] Failed to create temporary extraction directory"
        rm -f "$download_temp_file"

        exit 4
    fi

    if ! unzip -q "$download_temp_file" -d "$extract_dir"; then
        log_error "[$CANONICAL_ID] Failed to extract ZIP file"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file"

        exit 4
    fi

    # Find the .deb file in the extracted directory
    deb_file="$(find "$extract_dir" -name "*.deb" -print -quit)"
    
    if [[ -z "$deb_file" ]]; then
        log_error "[$CANONICAL_ID] No .deb file found in extracted ZIP"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file"

        exit 5
    fi

    log_info "[$CANONICAL_ID] Found .deb in ZIP: $deb_file"
    
    # Move the .deb to a permanent temporary location
    if ! final_deb_file="$(mktemp --suffix=.deb)"; then
        log_error "[$CANONICAL_ID] Failed to create final temporary package file"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file"

        exit 6
    fi

    if ! mv "$deb_file" "$final_deb_file"; then
        log_error "[$CANONICAL_ID] Failed to move the extracted package"
        rm -rf "$extract_dir"
        rm -f "$download_temp_file" "$final_deb_file"

        exit 7
    fi
    
    # Cleanup
    rm -rf "$extract_dir"
    rm -f "$download_temp_file"
    
    download_file="$final_deb_file"
else
    # It was already a .deb, just rename the temp file to have .deb suffix for clarity
    if ! final_deb_file="$(mktemp --suffix=.deb)"; then
        log_error "[$CANONICAL_ID] Failed to create final temporary package file"
        rm -f "$download_temp_file"

        exit 6
    fi

    if ! mv "$download_temp_file" "$final_deb_file"; then
        log_error "[$CANONICAL_ID] Failed to move the downloaded package"
        rm -f "$download_temp_file" "$final_deb_file"

        exit 7
    fi

    download_file="$final_deb_file"
fi

set_state "DEB_FILE" "$download_file"

if ! save_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to save installation state"
    rm -f "$download_file"

    exit 8
fi

log_info "[$CANONICAL_ID] Download completed successfully"
