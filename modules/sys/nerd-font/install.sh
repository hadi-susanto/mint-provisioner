#!/usr/bin/env bash

#
# Installs Nerd Font from a previously downloaded zip package.
#
# Exit codes:
#   0 - Installation successful
#   1 - nerd-font.path state file not found
#   2 - Invalid or missing package
#   3 - Extraction failed
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DOWNLOADED_FILE="$(get_state "DOWNLOAD_FILE")" || exit 1
FONT_NAME="$(get_state "FONT_NAME")" || exit 1

if [[ ! -f "$DOWNLOADED_FILE" ]]; then
    log_error "[$CANONICAL_ID] Downloaded file not found: ${DOWNLOADED_FILE}"
    exit 2
fi

BASE_FONT_DIR="/usr/local/share/fonts/nerd-font"
FONT_DIR="${BASE_FONT_DIR}/${FONT_NAME}"

log_info "[$CANONICAL_ID] Installing font to ${FONT_DIR}"

# Ensure font directory exists
sudo mkdir -p "$FONT_DIR"

# Extract the zip file
# -o: overwrite files without prompting
# -d: extract files into the specified directory
if ! sudo unzip -o "$DOWNLOADED_FILE" -d "$FONT_DIR"; then
    log_error "[$CANONICAL_ID] Extraction failed"
    exit 3
fi

log_info "[$CANONICAL_ID] Font installed successfully"

exit 0
