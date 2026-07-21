#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/messages.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

# Determine the target user (the one who invoked sudo, or the current user)
TARGET_USER="${SUDO_USER:-$USER}"

#
# Automate zsh config (.zshrc)
#
if [[ "${ZSH_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] ZSH_SKIP_CONFIGURATION is set to true, skipping zsh configuration"

    exit 0
fi

log_info "[$CANONICAL_ID] Changing default shell to zsh for user: $TARGET_USER"

if ! sudo chsh -s "$(which zsh)" "$TARGET_USER"; then
    log_error "[$CANONICAL_ID] Failed to change shell to zsh"

    exit 1
fi

msg="Default shell changed to zsh successfully
Don't forget re-login to apply shell changes"

log_info "[$CANONICAL_ID] $msg"
add_message "$CANONICAL_ID" "info" "$msg"

if [[ -z "${ZSH_FORCE_CONFIGURATION:-}" ]]; then
    ZSH_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

# 1. Copy payload files
PAYLOAD_FILE="general-config.zsh"
copy_to_config_dir "$CANONICAL_ID" "$PAYLOAD_DIR/$PAYLOAD_FILE" "ZSH_FORCE_CONFIGURATION"

# 2. Inspect ~/.zshrc and append source if missing
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/$PAYLOAD_FILE"

log_info "[$CANONICAL_ID] zsh configured successfully"
