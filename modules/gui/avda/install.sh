#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

install_path="$(expand_path "${AVDA_INSTALL_DIR:-$INSTALL_DIR/avda}")" || exit $?

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "zip" \
    "$install_path" \
    "build/avda" \
    "avda" || exit $?

icon_file="$(get_state "ICON_FILE")" || exit $?

install_desktop_entry "$CANONICAL_ID" "avda" "avda" "$install_path/build/avda" \
    --generic-name "OTP Viewer" \
    --comment "View one-time passwords from Aegis Authenticator backups" \
    --icon-file "$icon_file" \
    --icon-size "512x512" \
    --categories "Utility;Security;" \
    --keywords "OTP;TOTP;HOTP;Aegis;Authenticator;2FA;" || exit $?
