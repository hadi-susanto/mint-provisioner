#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

MODULE="zsh"

# Determine the target user (the one who invoked sudo, or the current user)
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(get_user_home)
ZSHRC_FILE="${USER_HOME}/.zshrc"

log_info "[$MODULE] Changing default shell to zsh for user: $TARGET_USER"

if ! sudo chsh -s "$(which zsh)" "$TARGET_USER"; then
    log_error "[$MODULE] Failed to change shell to zsh"

    return 1
fi

log_info "[$MODULE] Default shell changed to zsh successfully"
log_info "[$MODULE] Don't forget re-login to apply shell changes"

#
# Automate zsh config (.zshrc)
#
if [[ "${ZSH_SKIP_CONFIGURE:-${SKIP_CONFIGURE:-false}}" == "true" ]]; then
    log_warn "[$MODULE] ZSH_SKIP_CONFIGURE is set to true, skipping .zshrc configuration"

    return 0
fi

ZSH_CONFIG_DIR="${USER_HOME}/.config/mint-provisioner"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${ZSH_FORCE_CONFIGURE:-}" ]]; then
    ZSH_FORCE_CONFIGURE="${FORCE_CONFIGURE:-false}"
fi

# 1. Create zsh config directory if it doesn't exist
if [[ ! -d "$ZSH_CONFIG_DIR" ]]; then
    log_info "[$MODULE] Creating directory $ZSH_CONFIG_DIR"
    sudo -u "$TARGET_USER" mkdir -p "$ZSH_CONFIG_DIR"
fi

# 2. Determine which payload to use
PAYLOAD_FILE="general-config.zsh"
TARGET_PAYLOAD="$ZSH_CONFIG_DIR/$PAYLOAD_FILE"

# 3. Copy payload files to ~/.config/zsh/
if [[ ! -f "$TARGET_PAYLOAD" ]] || [[ "$ZSH_FORCE_CONFIGURE" == "true" ]]; then
    log_info "[$MODULE] Copying configuration file $PAYLOAD_FILE to $TARGET_PAYLOAD (configuration)"
    sudo -u "$TARGET_USER" cp "$SCRIPT_DIR/payload/$PAYLOAD_FILE" "$TARGET_PAYLOAD"
else
    log_warn "[$MODULE] $TARGET_PAYLOAD already exists and ZSH_FORCE_CONFIGURE is not true, skipping"
fi

# 4. Inspect ~/.zshrc and append source if missing
if [[ ! -f "$ZSHRC_FILE" ]]; then
    log_info "[$MODULE] Creating $ZSHRC_FILE"
    sudo -u "$TARGET_USER" touch "$ZSHRC_FILE"
fi

SOURCE_LINE="[[ -f \"$TARGET_PAYLOAD\" ]] && source \"$TARGET_PAYLOAD\""
if ! grep -Fq "$SOURCE_LINE" "$ZSHRC_FILE"; then
    log_info "[$MODULE] Adding source line to $ZSHRC_FILE"
    echo "$SOURCE_LINE" | sudo -u "$TARGET_USER" tee -a "$ZSHRC_FILE" > /dev/null
else
    log_warn "[$MODULE] Source line already exists in $ZSHRC_FILE"
fi

log_info "[$MODULE] .zshrc configured successfully at $ZSHRC_FILE"
