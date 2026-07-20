#!/usr/bin/env bash

#
# Post-install phase for SDKMAN!
#

source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${SDKMAN_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration as requested"

    exit 0
fi

if [[ -z "${SDKMAN_FORCE_CONFIGURATION:-}" ]]; then
    SDKMAN_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

if [[ -z "${SDKMAN_INSTALL_DIR:-}" ]]; then
    SDKMAN_INSTALL_DIR="$INSTALL_DIR/sdkman"
fi

log_info "[$CANONICAL_ID] Configuring SDKMAN!"

# Copy config from payload to SDKMAN install dir if it exists
PAYLOAD_CONFIG="${PAYLOAD_DIR}/config"
TARGET_CONFIG="${SDKMAN_INSTALL_DIR}/etc/config"

log_info "[$CANONICAL_ID] Copying configuration file to $TARGET_CONFIG"

SUDO_CMD=""
if ! can_write "$TARGET_CONFIG"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD cp "$PAYLOAD_CONFIG" "$TARGET_CONFIG"; then
    log_error "[$CANONICAL_ID] Failed to copy configuration file"

    exit 1
fi

# SDKMAN typically requires sourcing the init script.
# We'll create a small script in config dir to handle this and add it to shell sources.
CONFIG_DIR=$(get_config_dir)
SDKMAN_INIT_SH="${CONFIG_DIR}/sdkman-init.sh"

if [[ -f "$SDKMAN_INIT_SH" ]] && [[ "$SDKMAN_FORCE_CONFIGURATION" != "true" ]]; then
    log_warn "[$CANONICAL_ID] $SDKMAN_INIT_SH already exists, skipping creation. Set SDKMAN_FORCE_CONFIGURATION=true to overwrite."
else
    log_info "[$CANONICAL_ID] Creating SDKMAN! initialization script: $SDKMAN_INIT_SH"

    if [[ ! -d "$CONFIG_DIR" ]]; then
        if ! mkdir -p "$CONFIG_DIR"; then
            log_error "[$CANONICAL_ID] Failed to create configuration directory: $CONFIG_DIR"

            exit 2
        fi
    fi

    if ! printf '%s\n' \
        '# SDKMAN! initialization' \
        "export SDKMAN_DIR=\"$SDKMAN_INSTALL_DIR\"" \
        '[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"' \
        > "$SDKMAN_INIT_SH"
    then
        log_error "[$CANONICAL_ID] Failed to create initialization script: $SDKMAN_INIT_SH"

        exit 3
    fi
fi

if ! add_bash_source "$CANONICAL_ID" "$SDKMAN_INIT_SH"; then
    log_error "[$CANONICAL_ID] Failed to configure Bash integration"

    exit 4
fi

if ! add_zsh_source "$CANONICAL_ID" "$SDKMAN_INIT_SH"; then
    log_error "[$CANONICAL_ID] Failed to configure Zsh integration"

    exit 5
fi

log_info "[$CANONICAL_ID] Post-install configuration completed successfully"
