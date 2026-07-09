#!/usr/bin/env bash

#
# Post-install phase for SDKMAN!
#

source "${LIB_DIR}/installer_common.sh"

MODULE="sdkman"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${SDKMAN_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] Skipping configuration as requested"

    exit 0
fi

if [[ -z "${SDKMAN_FORCE_CONFIGURATION:-}" ]]; then
    SDKMAN_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

if [[ -z "${SDKMAN_INSTALL_DIR:-}" ]]; then
    SDKMAN_INSTALL_DIR="$INSTALL_DIR/sdkman"
fi

log_info "[$MODULE] Configuring SDKMAN!"

# Copy config from payload to SDKMAN install dir if it exists
PAYLOAD_CONFIG="${PAYLOAD_DIR}/config"
TARGET_CONFIG="${SDKMAN_INSTALL_DIR}/etc/config"

log_info "[$MODULE] Copying configuration file to $TARGET_CONFIG"

SUDO_CMD=""
if ! can_write "$TARGET_CONFIG"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD cp "$PAYLOAD_CONFIG" "$TARGET_CONFIG"; then
    log_error "[$MODULE] Failed to copy configuration file"
fi

# SDKMAN typically requires sourcing the init script.
# We'll create a small script in config dir to handle this and add it to shell sources.
CONFIG_DIR=$(get_config_dir)
SDKMAN_INIT_SH="${CONFIG_DIR}/sdkman-init.sh"

if [[ -f "$SDKMAN_INIT_SH" ]] && [[ "$SDKMAN_FORCE_CONFIGURATION" != "true" ]]; then
    log_warn "[$MODULE] $SDKMAN_INIT_SH already exists, skipping creation. Set SDKMAN_FORCE_CONFIGURATION=true to overwrite."
else
    log_info "[$MODULE] Creating SDKMAN! initialization script: $SDKMAN_INIT_SH"

    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi

    cat <<EOF > "$SDKMAN_INIT_SH"
# SDKMAN! initialization
export SDKMAN_DIR="$SDKMAN_INSTALL_DIR"
[[ -s "\${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "\${SDKMAN_DIR}/bin/sdkman-init.sh"
EOF
fi

add_bash_source "$MODULE" "$SDKMAN_INIT_SH"
add_zsh_source "$MODULE" "$SDKMAN_INIT_SH"

log_info "[$MODULE] Post-install configuration completed successfully"
