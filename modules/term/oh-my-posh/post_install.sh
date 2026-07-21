#!/usr/bin/env bash
set -euo pipefail

#
# Oh-my-posh post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${OH_MY_POSH_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] OH_MY_POSH_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${OH_MY_POSH_FORCE_CONFIGURATION:-}" ]]; then
    OH_MY_POSH_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$CANONICAL_ID" "$file" "OH_MY_POSH_FORCE_CONFIGURATION"
done

add_bash_source "$CANONICAL_ID" "$(get_config_dir)/oh-my-posh.sh"
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/oh-my-posh.zsh"

log_info "[$CANONICAL_ID] oh-my-posh configuration completed"
