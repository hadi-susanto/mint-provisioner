#!/usr/bin/env bash
set -euo pipefail

#
# Eza post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${EZA_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] EZA_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${EZA_FORCE_CONFIGURATION:-}" ]]; then
    EZA_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$CANONICAL_ID" "$file" "EZA_FORCE_CONFIGURATION"
done

add_bash_source "$CANONICAL_ID" "$(get_config_dir)/eza-aliases.sh"
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/eza-aliases.sh"

log_info "[$CANONICAL_ID] eza configuration completed"
