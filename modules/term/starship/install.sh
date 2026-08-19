#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.gz" \
    "${STARSHIP_INSTALL_DIR:-$INSTALL_DIR/starship}" \
    "starship" \
    "starship" || exit $?

msg="Starship requires a Nerd Font to be installed. Ensure you
have a Nerd Font installed.
To install one, you can use mint-provisioner."

add_message "$CANONICAL_ID" "info" "$msg"

msg="Unless System Toolkit is used to enable the shell
integration, follow the 'Add the init script to your
shell's config file' section:
  https://starship.rs/"

add_message "$CANONICAL_ID" "info" "$msg"

add_system_toolkit_message "$CANONICAL_ID"
