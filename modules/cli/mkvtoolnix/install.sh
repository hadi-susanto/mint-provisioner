#!/usr/bin/env bash
set -euo pipefail

source "$LIB_DIR/installer_apt.sh"
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

apt_install "$package" || exit 4

source "$LIB_DIR/messages.sh"

message="MkvToolNix package: '$package' has been installed successfully.

The provisioner has also installed several helper commands to simplify common MkvToolNix tasks.

Please reopen your terminal (or reload your shell) to load the new commands, then try:

  • mkvmerge-process
  • mkvmerge-extract-info"

add_message "$CANONICAL_ID" "info" "$message"
