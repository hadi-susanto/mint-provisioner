#!/usr/bin/env bash

#
# Installs SDKMAN! from downloaded archives.
#

source "${LIB_DIR}/installer_common.sh"

MODULE="sdkman"
STANDARD_STATE_FILE="${STATE_DIR}/sdkman.path"
NATIVE_STATE_FILE="${STATE_DIR}/sdkman-native.path"
VERSION_STATE_FILE="${STATE_DIR}/sdkman.version"
NATIVE_VERSION_STATE_FILE="${STATE_DIR}/sdkman-native.version"
CANDIDATES_STATE_FILE="${STATE_DIR}/sdkman-candidates.path"

if [[ ! -f "$STANDARD_STATE_FILE" ]] || [[ ! -f "$NATIVE_STATE_FILE" ]] || [[ ! -f "$CANDIDATES_STATE_FILE" ]]; then
    log_error "[$MODULE] State files not found"

    exit 1
fi

read -r STANDARD_ARCHIVE < "$STANDARD_STATE_FILE"
read -r NATIVE_ARCHIVE < "$NATIVE_STATE_FILE"
read -r SDKMAN_VERSION < "$VERSION_STATE_FILE"
read -r SDKMAN_NATIVE_VERSION < "$NATIVE_VERSION_STATE_FILE"
read -r CANDIDATES_FILE < "$CANDIDATES_STATE_FILE"

if [[ -z "${SDKMAN_INSTALL_DIR:-}" ]]; then
    SDKMAN_INSTALL_DIR="$INSTALL_DIR/sdkman"
fi

log_info "[$MODULE] Installing SDKMAN! to $SDKMAN_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$(dirname "$SDKMAN_INSTALL_DIR")"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$SDKMAN_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $SDKMAN_INSTALL_DIR"

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
        log_error "[$MODULE] Failed to unzip $archive"
        rm -rf "$temp_dir"

        return 1
    fi

    # Find the root folder in the temp dir
    local root_folder
    root_folder=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    if [[ -z "$root_folder" ]]; then
        log_error "[$MODULE] No root folder found in $archive"
        rm -rf "$temp_dir"

        return 2
    fi

    if ! $SUDO_CMD cp -r "${root_folder}/." "$dest/"; then
        log_error "[$MODULE] Failed to copy files from $root_folder to $dest"
        rm -rf "$temp_dir"

        return 3
    fi

    rm -rf "$temp_dir"

    return 0
}

log_info "[$MODULE] Extracting standard SDKMAN!"
if ! extract_strip_root "$STANDARD_ARCHIVE" "$SDKMAN_INSTALL_DIR"; then
    exit 3
fi

log_info "[$MODULE] Extracting native SDKMAN!"
if ! extract_strip_root "$NATIVE_ARCHIVE" "$SDKMAN_INSTALL_DIR"; then
    exit 4
fi

# Write SDKMAN! required data such as versions, platform, and candidates
log_info "[$MODULE] Writing versions, platform, and candidates"
echo "$SDKMAN_VERSION" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/version" > /dev/null
echo "$SDKMAN_NATIVE_VERSION" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/version_native" > /dev/null
echo "linuxx64" | $SUDO_CMD tee "$SDKMAN_INSTALL_DIR/var/platform" > /dev/null
$SUDO_CMD cp "$CANDIDATES_FILE" "$SDKMAN_INSTALL_DIR/var/candidates"

log_info "[$MODULE] Installation completed successfully"
