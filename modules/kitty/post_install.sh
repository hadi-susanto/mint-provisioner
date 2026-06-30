#!/usr/bin/env bash

#
# Kitty post-installation tasks
#

source "${LIB_DIR}/common.sh"

MODULE="kitty"
KITTY_CONFIG_DIR="$(get_user_home)/.config/kitty"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${KITTY_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] KITTY_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${KITTY_FORCE_CONFIGURATION:-}" ]]; then
    KITTY_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

log_info "[$MODULE] Configuring kitty default behavior based on mint-provisioner"

# 1. Create kitty config directory if it doesn't exist
if [[ ! -d "$KITTY_CONFIG_DIR" ]]; then
    log_info "[$MODULE] Creating directory $KITTY_CONFIG_DIR"
    mkdir -p "$KITTY_CONFIG_DIR"
fi

# 2. Copy payload files to ~/.config/kitty/
log_info "[$MODULE] Copying configuration files to $KITTY_CONFIG_DIR"

FILES=("mint-provisioner.kitty" "mint-provisioner.session")
for FILE in "${FILES[@]}"; do
    TARGET="$KITTY_CONFIG_DIR/$FILE"
    if [[ ! -f "$TARGET" ]] || [[ "$KITTY_FORCE_CONFIGURATION" == "true" ]]; then
        log_info "[$MODULE] Copying $FILE to $KITTY_CONFIG_DIR"
        cp "$SCRIPT_DIR/payload/$FILE" "$TARGET"
    else
        log_warn "[$MODULE] $FILE already exists and KITTY_FORCE_CONFIGURATION is not true, skipping"
    fi
done

# 3. Inspect ~/.config/kitty/kitty.conf and append include if missing
KITTY_CONF="$KITTY_CONFIG_DIR/kitty.conf"

if [[ ! -f "$KITTY_CONF" ]]; then
    log_info "[$MODULE] Creating $KITTY_CONF"
    touch "$KITTY_CONF"
fi

INCLUDE_LINE="include mint-provisioner.kitty"
if ! grep -Fxq "$INCLUDE_LINE" "$KITTY_CONF"; then
    log_info "[$MODULE] Adding '$INCLUDE_LINE' to $KITTY_CONF"
    echo "$INCLUDE_LINE" >> "$KITTY_CONF"
else
    log_warn "[$MODULE] '$INCLUDE_LINE' already exists in $KITTY_CONF"
fi

log_info "[$MODULE] kitty terminal should be configured based on mint-provisioner"
