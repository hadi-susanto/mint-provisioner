#!/usr/bin/env bash

#
# Eza post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="eza"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${EZA_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] EZA_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${EZA_FORCE_CONFIGURATION:-}" ]]; then
    EZA_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "EZA_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/eza-aliases.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/eza-aliases.sh"

log_info "[$MODULE] eza configuration completed"
