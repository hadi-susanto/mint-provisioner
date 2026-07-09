#!/usr/bin/env bash

#
# Ghostty post-installation tasks
#

source "${LIB_DIR}/common.sh"

MODULE="ghostty"
GHOSTTY_CONFIG_DIR="$(get_user_home)/.config/ghostty"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${GHOSTTY_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] GHOSTTY_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${GHOSTTY_FORCE_CONFIGURATION:-}" ]]; then
    GHOSTTY_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

log_info "[$MODULE] Configuring ghostty default behavior based on mint-provisioner"

# 1. Create ghostty config directory if it doesn't exist
if [[ ! -d "$GHOSTTY_CONFIG_DIR" ]]; then
    log_info "[$MODULE] Creating directory $GHOSTTY_CONFIG_DIR"
    mkdir -p "$GHOSTTY_CONFIG_DIR"
fi

# 2. Copy payload files to ~/.config/ghostty/
log_info "[$MODULE] Copying configuration files to $GHOSTTY_CONFIG_DIR"

FILE="mint-provisioner.ghostty"
TARGET="$GHOSTTY_CONFIG_DIR/$FILE"

if [[ ! -f "$TARGET" ]] || [[ "$GHOSTTY_FORCE_CONFIGURATION" == "true" ]]; then
    log_info "[$MODULE] Copying $FILE to $GHOSTTY_CONFIG_DIR"
    cp "$PAYLOAD_DIR/$FILE" "$TARGET"
else
    log_warn "[$MODULE] $FILE already exists and GHOSTTY_FORCE_CONFIGURATION is not true, skipping"
fi

# 3. Inspect ~/.config/ghostty/config.ghostty and append include if missing
GHOSTTY_CONF="$GHOSTTY_CONFIG_DIR/config.ghostty"

if [[ ! -f "$GHOSTTY_CONF" ]]; then
    log_info "[$MODULE] Creating $GHOSTTY_CONF"
    touch "$GHOSTTY_CONF"
fi

INCLUDE_LINE="config-file=\"$FILE\""
if ! grep -Fxq "$INCLUDE_LINE" "$GHOSTTY_CONF"; then
    log_info "[$MODULE] Adding '$INCLUDE_LINE' to $GHOSTTY_CONF"
    echo "$INCLUDE_LINE" >> "$GHOSTTY_CONF"
else
    log_warn "[$MODULE] '$INCLUDE_LINE' already exists in $GHOSTTY_CONF"
fi

log_info "[$MODULE] ghostty terminal should be configured based on mint-provisioner"
