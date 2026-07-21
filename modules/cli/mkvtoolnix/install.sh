#!/usr/bin/env bash
set -euo pipefail

source "$LIB_DIR/installer_apt.sh"
source "$LIB_DIR/messages.sh"
source "$LIB_DIR/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] MKVToolNix installation state was not found"

    exit 1
fi

package="$(get_state "MKVTOOLNIX_PACKAGE")" || exit 2

if [[ -z "$package" ]]; then
    log_error "MKVTOOLNIX_PACKAGE must not be empty"

    exit 3
fi

if ! apt_install "$package"; then
    add_message "$CANONICAL_ID" "warn" "Installation failed: $package"

    exit 4
fi

add_message "$CANONICAL_ID" "info" "Installation success: $package"

message="MkvToolNix package: '$package' has been installed successfully.

The provisioner has also installed several helper commands to simplify common MkvToolNix tasks.

Please reopen your terminal (or reload your shell) to load the new commands, then try:

  • mkvmerge-process
  • mkvmerge-extract-info"

add_message "$CANONICAL_ID" "info" "$message"
