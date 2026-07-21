#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

# Skip configuration if APT_FAST_SKIP_CONFIGURATION or SKIP_CONFIGURATION is set
if [[ "${APT_FAST_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] APT_FAST_SKIP_CONFIGURATION is set to true, skipping configuration"

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
        log_warn "[$CANONICAL_ID] Zsh autocompletion for apt-fast already exists. Use APT_FAST_FORCE_CONFIGURATION=true to overwrite."
    else
        log_info "[$CANONICAL_ID] Installing zsh autocompletion for apt-fast"

        if ! sudo install -Dm0644 "$ZSH_SOURCE_FILE" "$ZSH_TARGET_FILE"; then
            log_error "[$CANONICAL_ID] Failed to install Zsh autocompletion"

            exit 1
        fi
    fi
else
    log_info "[$CANONICAL_ID] Zsh is not installed, skipping zsh autocompletion for apt-fast"
fi

# Bash Autocompletion
if command -v bash >/dev/null 2>&1; then
    BASH_SOURCE_FILE="$PAYLOAD_DIR/bash-autocompletion"
    BASH_TARGET_DIR="/etc/bash_completion.d/"
    BASH_TARGET_FILE="$BASH_TARGET_DIR/apt-fast"

    if [[ -f "$BASH_TARGET_FILE" ]] && [[ "$APT_FAST_FORCE_CONFIGURATION" != "true" ]]; then
        log_warn "[$CANONICAL_ID] Bash autocompletion for apt-fast already exists. Use APT_FAST_FORCE_CONFIGURATION=true to overwrite."
    else
        log_info "[$CANONICAL_ID] Installing bash autocompletion for apt-fast"

        if ! sudo install -Dm0644 "$BASH_SOURCE_FILE" "$BASH_TARGET_FILE"; then
            log_error "[$CANONICAL_ID] Failed to install Bash autocompletion"

            exit 2
        fi
    fi
else
    log_info "[$CANONICAL_ID] Bash is not installed, skipping bash autocompletion for apt-fast"
fi
