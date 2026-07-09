#!/usr/bin/env bash

#
# bat post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="bat"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${BAT_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] BAT_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${BAT_FORCE_CONFIGURATION:-}" ]]; then
    BAT_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "BAT_FORCE_CONFIGURATION"
done

add_bash_source "$MODULE" "$(get_config_dir)/bat-aliases.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/bat-aliases.sh"

log_info "[$MODULE] bat configuration completed"

msg="Please be aware that cat now aliased to bat --pager=never"
msg+=$'\n'"We also introduce bat-help function to help colorize any --help"
msg+=$'\n'"Refer to https://github.com/flameshot-org/flameshot/releases/tag/v14.0.0"
post_message "$MODULE" "Please be aware that cat now aliased to bat --pager=never"
