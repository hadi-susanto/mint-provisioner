#!/usr/bin/env bash
source "$LIB_DIR/common.sh"

SOURCE="/etc/sudoers.d/0pwfeedback"
TARGET="/etc/sudoers.d/0pwfeedback.disabled"

if [[ -f "$TARGET" ]]; then
    log_info "Disabled file found at $TARGET. Terminal customization already applied."

    exit 0
fi

if [[ -f "$SOURCE" ]]; then
    log_info "Moving $SOURCE to $TARGET..."
    sudo mv "$SOURCE" "$TARGET"

    log_info "Terminal customization applied successfully."
else
    log_warn "$SOURCE not found, cannot apply terminal customization."
fi
