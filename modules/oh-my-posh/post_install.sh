#!/usr/bin/env bash

#
# Oh-my-posh post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="oh-my-posh"
USER_HOME=$(get_user_home)
CONFIG_DIR="${USER_HOME}/.config/mint-provisioner"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"

if [[ "${OH_MY_POSH_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] OH_MY_POSH_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${OH_MY_POSH_FORCE_CONFIGURATION:-}" ]]; then
    OH_MY_POSH_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
log_info "[$MODULE] Copying payloads to $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

for file in "$PAYLOAD_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        target="$CONFIG_DIR/$filename"
        if [[ ! -f "$target" ]] || [[ "$OH_MY_POSH_FORCE_CONFIGURATION" == "true" ]]; then
            log_info "[$MODULE] Copying $file to $target"
            cp "$file" "$target"
        else
          log_warn "[$MODULE] target already exists and OH_MY_POSH_FORCE_CONFIGURATION is not true, skipping"
        fi
    fi
done

add_bash_source "$MODULE" "${CONFIG_DIR}/oh-my-posh.sh"
add_zsh_source "$MODULE" "${CONFIG_DIR}/oh-my-posh.zsh"

log_info "[$MODULE] oh-my-posh configuration completed"
