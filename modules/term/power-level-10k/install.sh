#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/git-clone-install.sh"

declare -r POWERLEVEL10K_URL="https://github.com/romkatv/powerlevel10k.git"

git_clone_install \
    "$CANONICAL_ID" \
    "$POWERLEVEL10K_URL" \
    "${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}" \
    "powerlevel10k.zsh-theme"

install_path="$(get_registry "INSTALL_PATH")"
printf -v install_path_literal '%q' "$install_path"
printf -v theme_file_literal '%q' "$install_path/powerlevel10k.zsh-theme"

message="To enable Powerlevel10k through System Toolkit, run:
  export POWERLEVEL10K_INSTALL_DIR=$install_path_literal
  syskit-cfg install term/power-level-10k

Without System Toolkit, add the following to your Zsh configuration:
  source $theme_file_literal"
    
if ! add_message "$CANONICAL_ID" info "$message"; then
    tlog_warn "install:$CANONICAL_ID" "Failed to persist Powerlevel10k integration guidance"
fi

if command -v zsh >/dev/null 2>&1; then
    exit 0
fi

message="Zsh is not installed. Install it before enabling Powerlevel10k.
You can install Zsh using Mint Provisioner: 'mp install term/zsh'"

tlog_warn "install:$CANONICAL_ID" "Zsh is not installed; Powerlevel10k requires it"

if ! add_message "$CANONICAL_ID" warn "$message"; then
    tlog_warn "install:$CANONICAL_ID" "Failed to persist the missing-Zsh warning"
fi
