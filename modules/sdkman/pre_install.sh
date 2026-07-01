#!/usr/bin/env bash

#
# Pre-install phase for SDKMAN!
#

source "$LIB_DIR/installer_external.sh"

MODULE="sdkman"
SDKMAN_GET_URL="https://get.sdkman.io"

log_info "[$MODULE] Downloading SDKMAN! installer script to extract versions"

if ! get_script="$(mktemp --suffix=.sh)"; then
    log_error "[$MODULE] Failed to create temporary file for installer script"

    exit 1
fi

if ! curl -fL -o "$get_script" "$SDKMAN_GET_URL"; then
    log_error "[$MODULE] Failed to download $SDKMAN_GET_URL"
    rm -f "$get_script"

    exit 2
fi

# Extract variables from the script
SDKMAN_SERVICE=$(grep 'export SDKMAN_SERVICE=' "$get_script" | cut -d'"' -f2)
SDKMAN_VERSION=$(grep 'export SDKMAN_VERSION=' "$get_script" | cut -d'"' -f2)
SDKMAN_NATIVE_VERSION=$(grep 'export SDKMAN_NATIVE_VERSION=' "$get_script" | cut -d'"' -f2)

rm -f "$get_script"

if [[ -z "$SDKMAN_SERVICE" ]] || [[ -z "$SDKMAN_VERSION" ]] || [[ -z "$SDKMAN_NATIVE_VERSION" ]]; then
    log_error "[$MODULE] Failed to extract SDKMAN! metadata from installer script"

    exit 3
fi

log_info "[$MODULE] Extracted Service: $SDKMAN_SERVICE"
log_info "[$MODULE] Extracted Version: $SDKMAN_VERSION"
log_info "[$MODULE] Extracted Native Version: $SDKMAN_NATIVE_VERSION"

# Determine platform (default to linuxx64)
SDKMAN_PLATFORM="${SDKMAN_PLATFORM:-linuxx64}"

# Download standard SDKMAN
STANDARD_URL="${SDKMAN_SERVICE}/broker/download/sdkman/install/${SDKMAN_VERSION}/${SDKMAN_PLATFORM}"
STANDARD_FILE="$(mktemp --suffix=.zip)"
STANDARD_STATE_FILE="${STATE_DIR}/sdkman.path"
VERSION_STATE_FILE="${STATE_DIR}/sdkman.version"

if ! download_file "$MODULE" "$STANDARD_URL" "$STANDARD_FILE"; then
    log_error "[$MODULE] Failed to download standard SDKMAN!"
    rm -f "$STANDARD_FILE"

    exit 4
fi
printf '%s\n' "$STANDARD_FILE" > "$STANDARD_STATE_FILE"
printf '%s\n' "$SDKMAN_VERSION" > "$VERSION_STATE_FILE"

# Download native SDKMAN
NATIVE_URL="${SDKMAN_SERVICE}/broker/download/native/install/${SDKMAN_NATIVE_VERSION}/${SDKMAN_PLATFORM}"
NATIVE_FILE="$(mktemp --suffix=.zip)"
NATIVE_STATE_FILE="${STATE_DIR}/sdkman-native.path"
NATIVE_VERSION_STATE_FILE="${STATE_DIR}/sdkman-native.version"

if ! download_file "$MODULE" "$NATIVE_URL" "$NATIVE_FILE"; then
    log_error "[$MODULE] Failed to download native SDKMAN!"
    rm -f "$NATIVE_FILE"
    rm -f "$STANDARD_FILE" "$STANDARD_STATE_FILE" "$VERSION_STATE_FILE"

    exit 5
fi
printf '%s\n' "$NATIVE_FILE" > "$NATIVE_STATE_FILE"
printf '%s\n' "$SDKMAN_NATIVE_VERSION" > "$NATIVE_VERSION_STATE_FILE"

# Download candidates list
CANDIDATES_URL="${SDKMAN_SERVICE}/candidates/all"
CANDIDATES_FILE="$(mktemp --suffix=.txt)"
CANDIDATES_STATE_FILE="${STATE_DIR}/sdkman-candidates.path"

log_info "[$MODULE] Downloading candidates list from $CANDIDATES_URL"
if ! download_file "$MODULE" "$CANDIDATES_URL" "$CANDIDATES_FILE"; then
    log_error "[$MODULE] Failed to download candidates list"
    rm -f "$CANDIDATES_FILE"
    rm -f "$STANDARD_FILE" "$STANDARD_STATE_FILE" "$VERSION_STATE_FILE"
    rm -f "$NATIVE_FILE" "$NATIVE_STATE_FILE" "$NATIVE_VERSION_STATE_FILE"

    exit 6
fi
printf '%s\n' "$CANDIDATES_FILE" > "$CANDIDATES_STATE_FILE"

log_info "[$MODULE] Pre-install phase completed successfully"
