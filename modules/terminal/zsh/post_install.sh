#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="zsh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

# Determine the target user (the one who invoked sudo, or the current user)
TARGET_USER="${SUDO_USER:-$USER}"

#
# Automate zsh config (.zshrc)
#
if [[ "${ZSH_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] ZSH_SKIP_CONFIGURATION is set to true, skipping zsh configuration"

    return 0
fi

log_info "[$MODULE] Changing default shell to zsh for user: $TARGET_USER"

if ! sudo chsh -s "$(which zsh)" "$TARGET_USER"; then
    log_error "[$MODULE] Failed to change shell to zsh"

    return 1
fi

log_info "[$MODULE] Default shell changed to zsh successfully"
log_info "[$MODULE] Don't forget re-login to apply shell changes"

msg="Default shell changed to zsh successfully"
msg+=$'\n'"Don't forget re-login to apply shell changes"
post_message "$MODULE" "$msg"

if [[ -z "${ZSH_FORCE_CONFIGURATION:-}" ]]; then
    ZSH_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

# 1. Copy payload files
PAYLOAD_FILE="general-config.zsh"
copy_to_config_dir "$MODULE" "$PAYLOAD_DIR/$PAYLOAD_FILE" "ZSH_FORCE_CONFIGURATION"

# 2. Inspect ~/.zshrc and append source if missing
add_zsh_source "$MODULE" "$(get_config_dir)/$PAYLOAD_FILE"

log_info "[$MODULE] zsh configured successfully"
