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

MODULE="nerd-font"
STATE_FILE="${STATE_DIR}/nerd-font.path"
NAME_FILE="${STATE_DIR}/nerd-font.name"
BASE_FONT_DIR="/usr/local/share/fonts/nerd-font"

log_info "[$MODULE] Looking for state file: ${STATE_FILE}"

if [[ ! -f "$STATE_FILE" ]] || [[ ! -f "$NAME_FILE" ]]; then
    log_error "[$MODULE] State files not found"
    exit 1
fi

read -r DOWNLOADED_FILE < "$STATE_FILE"
read -r FONT_NAME < "$NAME_FILE"

if [[ ! -f "$DOWNLOADED_FILE" ]]; then
    log_error "[$MODULE] Downloaded file not found: ${DOWNLOADED_FILE}"
    exit 2
fi

FONT_DIR="${BASE_FONT_DIR}/${FONT_NAME}"

log_info "[$MODULE] Installing font to ${FONT_DIR}"

# Ensure font directory exists
sudo mkdir -p "$FONT_DIR"

# Extract the zip file
# -o: overwrite files without prompting
# -d: extract files into the specified directory
if ! sudo unzip -o "$DOWNLOADED_FILE" -d "$FONT_DIR"; then
    log_error "[$MODULE] Extraction failed"
    exit 3
fi

log_info "[$MODULE] Font installed successfully"

exit 0
