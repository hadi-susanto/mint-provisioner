#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="git-ui"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"

if [[ "${GIT_UI_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] GIT_UI_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${GIT_UI_FORCE_CONFIGURATION:-}" ]]; then
    GIT_UI_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "GIT_UI_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/git-ui-aliases.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/git-ui-aliases.sh"
