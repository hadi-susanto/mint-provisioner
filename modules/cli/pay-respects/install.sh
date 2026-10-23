#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

msg="Unless System Toolkit is used to enable the shell
integration, add this line to your shell's config file:
  eval \"\$(pay-respects bash --alias)\"   # ~/.bashrc
  eval \"\$(pay-respects zsh --alias)\"    # ~/.zshrc
Then press F after a failed command to apply the fix."

add_message "$CANONICAL_ID" "info" "$msg"

add_system_toolkit_message "$CANONICAL_ID"
