#!/usr/bin/env bash
set -euo pipefail

#
# bat post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/messages.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="${SCRIPT_DIR}/payload"

if [[ "${BAT_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] BAT_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${BAT_FORCE_CONFIGURATION:-}" ]]; then
    BAT_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$CANONICAL_ID" "$file" "BAT_FORCE_CONFIGURATION"
done

add_bash_source "$CANONICAL_ID" "$(get_config_dir)/bat-aliases.sh"
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/bat-aliases.sh"

log_info "[$CANONICAL_ID] bat configuration completed"

msg="Please be aware that cat now aliased to bat --pager=never
We also introduce bat-help function to help colorize any --help"

log_info "$msg"
add_message "$CANONICAL_ID" "info" "$msg"
