#!/usr/bin/env bash

#
# Starship post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="starship"
USER_HOME=$(get_user_home)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${STARSHIP_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] STARSHIP_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${STARSHIP_FORCE_CONFIGURATION:-}" ]]; then
    STARSHIP_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for filename in "starship.sh" "starship.zsh"; do
    copy_to_config_dir "$MODULE" "${PAYLOAD_DIR}/${filename}" "STARSHIP_FORCE_CONFIGURATION"
done

add_zsh_source "$MODULE" "$(get_config_dir)/starship.zsh"
add_bash_source "$MODULE" "$(get_config_dir)/starship.sh"

#
# Starship toml check
#
STARSHIP_TOML="${USER_HOME}/.config/starship.toml"
if [[ ! -f "$STARSHIP_TOML" ]]; then
    log_info "[$MODULE] $STARSHIP_TOML not found, copying from payload"
    cp "${PAYLOAD_DIR}/starship.toml" "$STARSHIP_TOML"
elif ! grep -q "add_newline" "$STARSHIP_TOML"; then
    log_info "[$MODULE] Adding add_newline = false to $STARSHIP_TOML"
    # Prepend to the file
    echo -e "# Mint Provisioner Starship Auto Configuration\nadd_newline = false\n\n$(cat "$STARSHIP_TOML")" > "$STARSHIP_TOML"
else
    log_warn "[$MODULE] $STARSHIP_TOML exists but already contains add_newline statement. Please update to false manually."
    post_message "$MODULE" "$STARSHIP_TOML exists but already contains add_newline statement. Please update to false manually."
fi

log_info "[$MODULE] starship configuration completed"
