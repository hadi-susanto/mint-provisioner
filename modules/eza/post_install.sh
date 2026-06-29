#!/usr/bin/env bash

#
# Eza post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="eza"
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(get_user_home)
CONFIG_DIR="${USER_HOME}/.config/mint-provisioner"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"

if [[ "${EZA_SKIP_CONFIGURE:-${SKIP_CONFIGURE:-false}}" == "true" ]]; then
    log_warn "[$MODULE] EZA_SKIP_CONFIGURE is set to true, skipping configuration"

    return 0
fi

if [[ -z "${EZA_FORCE_CONFIGURE:-}" ]]; then
    EZA_FORCE_CONFIGURE="${FORCE_CONFIGURE:-false}"
fi

#
# Copy payloads
#
log_info "[$MODULE] Copying payloads to $CONFIG_DIR"
if [[ ! -d "$CONFIG_DIR" ]]; then
    sudo -u "$TARGET_USER" mkdir -p "$CONFIG_DIR"
fi

for file in "$PAYLOAD_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        target="$CONFIG_DIR/$filename"
        if [[ ! -f "$target" ]] || [[ "$EZA_FORCE_CONFIGURE" == "true" ]]; then
            log_info "[$MODULE] Copying $file to $target"
            sudo -u "$TARGET_USER" cp "$file" "$target"
        else
          log_warn "[$MODULE] target already exists and EZA_FORCE_CONFIGURE is not true, skipping"
        fi
    fi
done

add_bash_source "$MODULE" "${CONFIG_DIR}/eza-aliases.sh"
add_zsh_source "$MODULE" "${CONFIG_DIR}/eza-aliases.sh"

log_info "[$MODULE] eza configuration completed"
