#!/usr/bin/env bash

#
# Installs SDKMAN! from downloaded archives.
#

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
STANDARD_ARCHIVE="$(get_state "STANDARD_FILE")" || exit 1
NATIVE_ARCHIVE="$(get_state "NATIVE_FILE")" || exit 1
SDKMAN_VERSION="$(get_state "SDKMAN_VERSION")" || exit 1
SDKMAN_NATIVE_VERSION="$(get_state "SDKMAN_NATIVE_VERSION")" || exit 1
CANDIDATES_FILE="$(get_state "CANDIDATES_FILE")" || exit 1

if [[ -z "${SDKMAN_INSTALL_DIR:-}" ]]; then
    SDKMAN_INSTALL_DIR="$INSTALL_DIR/sdkman"
fi

log_info "[$CANONICAL_ID] Installing SDKMAN! to $SDKMAN_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$SDKMAN_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $SDKMAN_INSTALL_DIR"

    exit 2
fi

# SDKMAN requires some basic structure if not present
$SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR/tmp"
$SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR/ext"
$SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR/etc"
$SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR/var"
$SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR/candidates"

# Function to extract zip and strip root folder
# Eg: assume zip path is a/b/c then copy content of folder a to install dir
extract_strip_root() {
    local archive="$1"
    local dest="$2"
    local temp_dir
    temp_dir=$(mktemp -d)

    if ! unzip -q "$archive" -d "$temp_dir"; then
        log_error "[$CANONICAL_ID] Failed to unzip $archive"
        rm -rf "$temp_dir"

        return 1
    fi

    # Find the root folder in the temp dir
    local root_folder
    root_folder=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    if [[ -z "$root_folder" ]]; then
        log_error "[$CANONICAL_ID] No root folder found in $archive"
        rm -rf "$temp_dir"

        return 2
    fi

    if ! $SUDO_CMD cp -r "${root_folder}/." "$dest/"; then
        log_error "[$CANONICAL_ID] Failed to copy files from $root_folder to $dest"
        rm -rf "$temp_dir"

        return 3
    fi

    rm -rf "$temp_dir"

    return 0
}

log_info "[$CANONICAL_ID] Extracting standard SDKMAN!"
if ! extract_strip_root "$STANDARD_ARCHIVE" "$SDKMAN_INSTALL_DIR"; then
    exit 3
fi

log_info "[$CANONICAL_ID] Extracting native SDKMAN!"
if ! extract_strip_root "$NATIVE_ARCHIVE" "$SDKMAN_INSTALL_DIR"; then
    exit 4
fi

# Write SDKMAN! required data such as versions, platform, and candidates
log_info "[$CANONICAL_ID] Writing versions, platform, and candidates"
echo "$SDKMAN_VERSION" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/version" > /dev/null
echo "$SDKMAN_NATIVE_VERSION" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/version_native" > /dev/null
echo "linuxx64" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/platform" > /dev/null
$SUDO_CMD cp "$CANDIDATES_FILE" "$SDKMAN_INSTALL_DIR/var/candidates"

log_info "[$CANONICAL_ID] Installation completed successfully"
