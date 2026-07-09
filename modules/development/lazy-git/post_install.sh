#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="lazy-git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${LAZY_GIT_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] LAZY_GIT_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${LAZY_GIT_FORCE_CONFIGURATION:-}" ]]; then
    LAZY_GIT_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "LAZY_GIT_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/lazy-git-aliases.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/lazy-git-aliases.sh"
