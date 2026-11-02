#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

install_path="$(expand_path "${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}")" || exit $?

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "$install_path" \
    "app/Postman" \
    "postman" \
    -- \
    "--strip-components=1" || exit $?
install_desktop_entry "$CANONICAL_ID" "postman" "Postman" "$install_path/app/Postman" \
    --exec-args "%U" \
    --try-exec "$install_path/app/Postman" \
    --comment "Build, test, and document APIs" \
    --icon "$install_path/app/resources/app/assets/icon.png" \
    --categories "Development;" \
    --keywords "API;HTTP;REST;GraphQL;Testing;" \
    --startup-wm-class "Postman"
