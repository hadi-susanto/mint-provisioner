#!/usr/bin/env bash
set -euo pipefail

#
# Starship post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/messages.sh"

USER_HOME="$(get_user_home)" || exit $?
SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${STARSHIP_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] STARSHIP_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${STARSHIP_FORCE_CONFIGURATION:-}" ]]; then
    STARSHIP_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for filename in "starship.sh" "starship.zsh"; do
    copy_to_config_dir "$CANONICAL_ID" "${PAYLOAD_DIR}/${filename}" "STARSHIP_FORCE_CONFIGURATION"
done

add_zsh_source "$CANONICAL_ID" "$(get_config_dir)/starship.zsh"
add_bash_source "$CANONICAL_ID" "$(get_config_dir)/starship.sh"

#
# Starship toml check
#
STARSHIP_TOML="${USER_HOME}/.config/starship.toml"
if [[ ! -f "$STARSHIP_TOML" ]]; then
    log_info "[$CANONICAL_ID] $STARSHIP_TOML not found, copying from payload"
    cp "${PAYLOAD_DIR}/starship.toml" "$STARSHIP_TOML"
elif ! grep -q "add_newline" "$STARSHIP_TOML"; then
    log_info "[$CANONICAL_ID] Adding add_newline = false to $STARSHIP_TOML"
    # Prepend to the file
    echo -e "# Mint Provisioner Starship Auto Configuration\nadd_newline = false\n\n$(cat "$STARSHIP_TOML")" > "$STARSHIP_TOML"
else
    msg="$STARSHIP_TOML exists but already contains add_newline statement. Please update to false manually."

    log_warn "[$CANONICAL_ID] $msg"
    add_message "$CANONICAL_ID" "warn" "$msg"
fi

log_info "[$CANONICAL_ID] starship configuration completed"
