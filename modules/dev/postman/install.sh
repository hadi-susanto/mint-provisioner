#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path
    local tag="install:$canonical_id"

    install_path="$(expand_path "$raw_install_path")" || return $?
    stateful_extract_install \
        "$canonical_id" \
        "ARCHIVE_FILE" \
        "tar" \
        "$install_path" \
        "app/Postman" \
        "postman" \
        -- \
        "--strip-components=1" || return $?
    install_desktop_entry "$canonical_id" "postman" "Postman" "$install_path/app/Postman" \
        --exec-args "%U" \
        --try-exec "$install_path/app/Postman" \
        --comment "Build, test, and document APIs" \
        --icon "$install_path/app/resources/app/assets/icon.png" \
        --categories "Development;" \
        --keywords "API;HTTP;REST;GraphQL;Testing;" \
        --startup-wm-class "Postman"
}

main "$CANONICAL_ID" "${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"
