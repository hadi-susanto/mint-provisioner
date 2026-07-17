#!/usr/bin/env bash

#
# Pre-install phase for SDKMAN!
#

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

SDKMAN_GET_URL="https://get.sdkman.io"

log_info "[$CANONICAL_ID] Downloading SDKMAN! installer script to extract versions"

if ! get_script="$(mktemp --suffix=.sh)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file for installer script"

    exit 1
fi

if ! curl -fL -o "$get_script" "$SDKMAN_GET_URL"; then
    log_error "[$CANONICAL_ID] Failed to download $SDKMAN_GET_URL"
    rm -f "$get_script"

    exit 2
fi

# Extract variables from the script
SDKMAN_SERVICE=$(grep 'export SDKMAN_SERVICE=' "$get_script" | cut -d'"' -f2)
SDKMAN_VERSION=$(grep 'export SDKMAN_VERSION=' "$get_script" | cut -d'"' -f2)
SDKMAN_NATIVE_VERSION=$(grep 'export SDKMAN_NATIVE_VERSION=' "$get_script" | cut -d'"' -f2)

rm -f "$get_script"

if [[ -z "$SDKMAN_SERVICE" ]] || [[ -z "$SDKMAN_VERSION" ]] || [[ -z "$SDKMAN_NATIVE_VERSION" ]]; then
    log_error "[$CANONICAL_ID] Failed to extract SDKMAN! metadata from installer script"

    exit 3
fi

log_info "[$CANONICAL_ID] Extracted Service: $SDKMAN_SERVICE"
log_info "[$CANONICAL_ID] Extracted Version: $SDKMAN_VERSION"
log_info "[$CANONICAL_ID] Extracted Native Version: $SDKMAN_NATIVE_VERSION"

# Determine platform (default to linuxx64)
SDKMAN_PLATFORM="${SDKMAN_PLATFORM:-linuxx64}"

# Download standard SDKMAN
STANDARD_URL="${SDKMAN_SERVICE}/broker/download/sdkman/install/${SDKMAN_VERSION}/${SDKMAN_PLATFORM}"
STANDARD_FILE="$(mktemp --suffix=.zip)"

if ! download_file "$CANONICAL_ID" "$STANDARD_URL" "$STANDARD_FILE"; then
    log_error "[$CANONICAL_ID] Failed to download standard SDKMAN!"
    rm -f "$STANDARD_FILE"

    exit 4
fi

# Download native SDKMAN
NATIVE_URL="${SDKMAN_SERVICE}/broker/download/native/install/${SDKMAN_NATIVE_VERSION}/${SDKMAN_PLATFORM}"
NATIVE_FILE="$(mktemp --suffix=.zip)"

if ! download_file "$CANONICAL_ID" "$NATIVE_URL" "$NATIVE_FILE"; then
    log_error "[$CANONICAL_ID] Failed to download native SDKMAN!"
    rm -f "$NATIVE_FILE"
    rm -f "$STANDARD_FILE"

    exit 5
fi

# Download candidates list
CANDIDATES_URL="${SDKMAN_SERVICE}/candidates/all"
CANDIDATES_FILE="$(mktemp --suffix=.txt)"

log_info "[$CANONICAL_ID] Downloading candidates list from $CANDIDATES_URL"
if ! download_file "$CANONICAL_ID" "$CANDIDATES_URL" "$CANDIDATES_FILE"; then
    log_error "[$CANONICAL_ID] Failed to download candidates list"
    rm -f "$CANDIDATES_FILE"
    rm -f "$STANDARD_FILE"
    rm -f "$NATIVE_FILE"

    exit 6
fi

set_state "STANDARD_FILE" "$STANDARD_FILE"
set_state "SDKMAN_VERSION" "$SDKMAN_VERSION"
set_state "NATIVE_FILE" "$NATIVE_FILE"
set_state "SDKMAN_NATIVE_VERSION" "$SDKMAN_NATIVE_VERSION"
set_state "CANDIDATES_FILE" "$CANDIDATES_FILE"
save_states "$CANONICAL_ID" || exit 7

log_info "[$CANONICAL_ID] Pre-install phase completed successfully"
