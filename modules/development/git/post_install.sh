#!/usr/bin/env bash

#
# Git post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${GIT_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] GIT_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${GIT_FORCE_CONFIGURATION:-}" ]]; then
    GIT_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "GIT_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/git-aliases.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/git-aliases.sh"

log_info "[$MODULE] git configuration completed"
