#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local install_path
    local tag="install:$canonical_id"

    install_path="$(expand_path "$raw_install_path")" || return $?
    stateful_extract \
        "$canonical_id" \
        "ARCHIVE_FILE" \
        "tar" \
        "$install_path" \
        "--strip-components=1" || $return $?

    add_to_path "$canonical_id" "$install_path/bin" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?

    if command -v java >/dev/null 2>&1; then
        return 0
    fi

    message="Java not found. Apache Maven requires Java; please install it"
    tlog_warn "$tag" "%s" "$message"
    add_message "$canonical_id" warn "$message"
}

main "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}"
