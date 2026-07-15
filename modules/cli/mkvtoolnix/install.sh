#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"
source "$LIB_DIR/state.sh"
source "$LIB_DIR/messages.sh"

load_states "$CANONICAL_ID" || log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

if [[ "$(get_state "MKVTOOLNIX_GUI_ENABLED" "false")" == "true" ]]; then
    log_info "[$CANONICAL_ID] Installing mkvtoolnix-gui (CLI + GUI)"

    apt_install mkvtoolnix-gui

    message=$'MkvToolNix GUI and CLI have been installed successfully.\n\nThe provisioner has also installed several helper commands to simplify common MkvToolNix tasks.\n\nPlease reopen your terminal (or reload your shell) to load the new commands, then try:\n\n  • mkvmerge-process\n  • mkvmerge-extract-info'
    add_message "$CANONICAL_ID" "info" "$message"
else
    log_info "[$CANONICAL_ID] Installing mkvtoolnix (CLI only)"

    apt_install mkvtoolnix

    message=$'MkvToolNix CLI has been installed successfully.\n\nThe provisioner has also installed several helper commands to simplify common MkvToolNix tasks.\n\nPlease reopen your terminal (or reload your shell) to load the new commands, then try:\n\n  • mkvmerge-process\n  • mkvmerge-extract-info'
    add_message "$CANONICAL_ID" "info" "$message"
fi
