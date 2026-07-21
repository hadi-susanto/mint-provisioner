#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

KITTY_CONFIG_DIR="$(get_user_home)/.config/kitty"
SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${KITTY_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] KITTY_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${KITTY_FORCE_CONFIGURATION:-}" ]]; then
    KITTY_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

log_info "[$CANONICAL_ID] Configuring kitty default behavior based on mint-provisioner"

# 1. Create kitty config directory if it doesn't exist
if [[ ! -d "$KITTY_CONFIG_DIR" ]]; then
    log_info "[$CANONICAL_ID] Creating directory $KITTY_CONFIG_DIR"
    mkdir -p "$KITTY_CONFIG_DIR"
fi

# 2. Copy payload files to ~/.config/kitty/
log_info "[$CANONICAL_ID] Copying configuration files to $KITTY_CONFIG_DIR"

FILES=("mint-provisioner.kitty" "mint-provisioner.session")
for FILE in "${FILES[@]}"; do
    TARGET="$KITTY_CONFIG_DIR/$FILE"
    if [[ ! -f "$TARGET" ]] || [[ "$KITTY_FORCE_CONFIGURATION" == "true" ]]; then
        log_info "[$CANONICAL_ID] Copying $FILE to $KITTY_CONFIG_DIR"
        cp "$PAYLOAD_DIR/$FILE" "$TARGET"
    else
        log_warn "[$CANONICAL_ID] $FILE already exists and KITTY_FORCE_CONFIGURATION is not true, skipping"
    fi
done

# 3. Inspect ~/.config/kitty/kitty.conf and append include if missing
KITTY_CONF="$KITTY_CONFIG_DIR/kitty.conf"

if [[ ! -f "$KITTY_CONF" ]]; then
    log_info "[$CANONICAL_ID] Creating $KITTY_CONF"
    touch "$KITTY_CONF"
fi

INCLUDE_LINE="include mint-provisioner.kitty"
if ! grep -Fxq "$INCLUDE_LINE" "$KITTY_CONF"; then
    log_info "[$CANONICAL_ID] Adding '$INCLUDE_LINE' to $KITTY_CONF"
    echo "$INCLUDE_LINE" >> "$KITTY_CONF"
else
    log_warn "[$CANONICAL_ID] '$INCLUDE_LINE' already exists in $KITTY_CONF"
fi

log_info "[$CANONICAL_ID] kitty terminal should be configured based on mint-provisioner"
