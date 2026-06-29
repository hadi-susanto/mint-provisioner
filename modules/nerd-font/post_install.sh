#!/usr/bin/env bash

#
# Post-install phase for Nerd Font.
#
# Actions:
#   1. Invalidate font cache to ensure the new font is loaded.
#

source "${LIB_DIR}/common.sh"

MODULE="nerd-font"
NAME_FILE="${STATE_DIR}/nerd-font.name"
BASE_FONT_DIR="/usr/local/share/fonts/nerd-font"

if [[ ! -f "$NAME_FILE" ]]; then
    log_warn "[$MODULE] Name state file not found, invalidating all fonts"
    TARGET_DIR="$BASE_FONT_DIR"
else
    read -r FONT_NAME < "$NAME_FILE"
    TARGET_DIR="${BASE_FONT_DIR}/${FONT_NAME}"
fi

log_info "[$MODULE] Invalidating font cache for: $TARGET_DIR"

if ! sudo fc-cache -fv "$TARGET_DIR"; then
    log_warn "[$MODULE] Failed to invalidate font cache, you may need to run 'fc-cache -fv' manually"
fi

log_info "[$MODULE] Post-install completed"
