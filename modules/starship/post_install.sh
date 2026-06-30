#!/usr/bin/env bash

#
# Starship post-installation tasks
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_common.sh"

MODULE="starship"
USER_HOME=$(get_user_home)
CONFIG_DIR="${USER_HOME}/.config/mint-provisioner"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"

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
log_info "[$MODULE] Copying shell payloads to $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

for filename in "starship.sh" "starship.zsh"; do
    file="${PAYLOAD_DIR}/${filename}"
    if [[ -f "$file" ]]; then
        target="$CONFIG_DIR/$filename"
        if [[ ! -f "$target" ]] || [[ "$STARSHIP_FORCE_CONFIGURATION" == "true" ]]; then
            log_info "[$MODULE] Copying $file to $target"
            cp "$file" "$target"
        else
          log_warn "[$MODULE] '$filename' already exists and STARSHIP_FORCE_CONFIGURATION is not true, skipping"
        fi
    fi
done

add_zsh_source "$MODULE" "${CONFIG_DIR}/starship.zsh"
add_bash_source "$MODULE" "${CONFIG_DIR}/starship.sh"

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
