#!/usr/bin/env bash

#
# power-level-10k post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="power-level-10k"
if [[ -z "${POWERLEVEL10K_INSTALL_DIR:-}" ]]; then
    POWERLEVEL10K_INSTALL_DIR="$INSTALL_DIR/power-level-10k"
fi
THEME_FILE="${POWERLEVEL10K_INSTALL_DIR}/powerlevel10k.zsh-theme"

if [[ "${POWERLEVEL10K_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] POWERLEVEL10K_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    log_warn "[$MODULE] zsh is not installed, skipping configuration"

    exit 0
fi

add_zsh_source "$MODULE" "$THEME_FILE"

log_info "[$MODULE] $MODULE configuration completed"
