#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${GIT_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] GIT_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${GIT_FORCE_CONFIGURATION:-}" ]]; then
    GIT_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$CANONICAL_ID" "$file" "GIT_FORCE_CONFIGURATION"
done

add_bash_source "$CANONICAL_ID" "$(get_config_dir)/git-aliases.sh"
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/git-aliases.sh"

log_info "[$CANONICAL_ID] git configuration completed"
