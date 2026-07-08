#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

MODULE="apt-fast"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"
 
# Skip configuration if APT_FAST_SKIP_CONFIGURATION or SKIP_CONFIGURATION is set
if [[ "${APT_FAST_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] APT_FAST_SKIP_CONFIGURATION is set to true, skipping configuration"

    exit 0
fi

if [[ -z "${APT_FAST_FORCE_CONFIGURATION:-}" ]]; then
    APT_FAST_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

# ZSH Autocompletion
if command -v zsh >/dev/null 2>&1; then
    ZSH_SOURCE_FILE="$PAYLOAD_DIR/zsh-autocompletion"
    ZSH_TARGET_DIR="/usr/share/zsh/functions/Completion/Debian"
    ZSH_TARGET_FILE="$ZSH_TARGET_DIR/_apt-fast"

    if [[ -f "$ZSH_TARGET_FILE" ]] && [[ "$APT_FAST_FORCE_CONFIGURATION" != "true" ]]; then
        log_warn "[$MODULE] Zsh autocompletion for apt-fast already exists. Use APT_FAST_FORCE_CONFIGURATION=true to overwrite."
    else
        log_info "[$MODULE] Installing zsh autocompletion for apt-fast"
        sudo mkdir -p "$ZSH_TARGET_DIR"
        sudo cp "$ZSH_SOURCE_FILE" "$ZSH_TARGET_FILE"
        sudo chown root:root "$ZSH_TARGET_FILE"
    fi
else
    log_info "[$MODULE] Zsh is not installed, skipping zsh autocompletion for apt-fast"
fi

# Bash Autocompletion
if command -v bash >/dev/null 2>&1; then
    BASH_SOURCE_FILE="$PAYLOAD_DIR/bash-autocompletion"
    BASH_TARGET_DIR="/etc/bash_completion.d/"
    BASH_TARGET_FILE="$BASH_TARGET_DIR/apt-fast"

    if [[ -f "$BASH_TARGET_FILE" ]] && [[ "$APT_FAST_FORCE_CONFIGURATION" != "true" ]]; then
        log_warn "[$MODULE] Bash autocompletion for apt-fast already exists. Use APT_FAST_FORCE_CONFIGURATION=true to overwrite."
    else
        log_info "[$MODULE] Installing bash autocompletion for apt-fast"
        sudo mkdir -p "$BASH_TARGET_DIR"
        sudo cp "$BASH_SOURCE_FILE" "$BASH_TARGET_FILE"
        sudo chown root:root "$BASH_TARGET_FILE"
    fi
else
    log_info "[$MODULE] Bash is not installed, skipping bash autocompletion for apt-fast"
fi
