#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"

install_path="${POWERLEVEL10K_INSTALL_DIR:-}"

if [[ -n "$install_path" ]]; then
    [[ -f "$install_path/powerlevel10k.zsh-theme" ]]

    exit $?
fi

# Fortunately, when no state file it will return 1, match our contract
# for installed should return 1 for not installed, > 1 for error
load_registry "$CANONICAL_ID" silent || exit $?
install_path="$(get_registry "INSTALL_PATH" 2>/dev/null)" || exit 2

[[ -f "$install_path/powerlevel10k.zsh-theme" ]]
