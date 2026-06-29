#!/usr/bin/env bash

#
# power-level-10k post-installation tasks
#

source "${LIB_DIR}/common.sh"

MODULE="power-level-10k"
USER_HOME=$(get_user_home)
INSTALL_BASE_DIR="${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"
THEME_FILE="${INSTALL_BASE_DIR}/powerlevel10k.zsh-theme"

if [[ "${POWERLEVEL10K_SKIP_CONFIGURE:-${SKIP_CONFIGURE:-false}}" == "true" ]]; then
    log_warn "[$MODULE] POWERLEVEL10K_SKIP_CONFIGURE is set to true, skipping configuration"

    exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    log_warn "[$MODULE] zsh is not installed, skipping configuration"

    exit 0
fi

if [[ -z "${POWERLEVEL10K_FORCE_CONFIGURE:-}" ]]; then
    POWERLEVEL10K_FORCE_CONFIGURE="${FORCE_CONFIGURE:-false}"
fi

log_info "[$MODULE] Configuring $MODULE for zsh"

RC_FILE="${USER_HOME}/.zshrc"

if [[ ! -f "$RC_FILE" ]]; then
    log_info "[$MODULE] Creating $RC_FILE"

    touch "$RC_FILE"
fi

SOURCE_LINE="[[ -f \"$THEME_FILE\" ]] && source \"$THEME_FILE\""

if grep -Fq "$SOURCE_LINE" "$RC_FILE"; then
    if [[ "$POWERLEVEL10K_FORCE_CONFIGURE" == "true" ]]; then
        # Since it is just one line, we can just let it be or remove and re-add.
        # For simplicity, we can use sed to remove it if it exists and then append it.
        # But grep -Fq then echo is standard here.
        # If we want to "overwrite", maybe we just ensure it is there.
        # If the line is already there, there is nothing to overwrite unless the path changed.
        log_warn "[$MODULE] Configuration overwrite requested but source line already exists. Path: $THEME_FILE"
    else
        log_warn "[$MODULE] $MODULE source already exists in $RC_FILE and configuration is not true, skipping"

        exit 0
    fi
fi

if ! grep -Fq "$SOURCE_LINE" "$RC_FILE"; then
    log_info "[$MODULE] Adding $MODULE source to $RC_FILE"
    echo "$SOURCE_LINE" >> "$RC_FILE"
fi

log_info "[$MODULE] $MODULE configuration completed"
