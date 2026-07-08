#!/usr/bin/env bash

#
# Oh-my-posh post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="oh-my-posh"
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
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "OH_MY_POSH_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/oh-my-posh.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/oh-my-posh.zsh"

log_info "[$MODULE] oh-my-posh configuration completed"
