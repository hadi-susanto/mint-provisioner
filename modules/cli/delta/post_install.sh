#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${DELTA_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] DELTA_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${DELTA_FORCE_CONFIGURATION:-}" ]]; then
    DELTA_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$CANONICAL_ID" "$file" "DELTA_FORCE_CONFIGURATION"
done

add_bash_source "$CANONICAL_ID" "$(get_config_dir)/delta-aliases.sh"
add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/delta-aliases.sh"
