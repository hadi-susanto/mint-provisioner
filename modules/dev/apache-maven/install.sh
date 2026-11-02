#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="install:$CANONICAL_ID"
install_path="$(expand_path "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}")" || exit $?

stateful_extract \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "$install_path" \
    "--strip-components=1" || exit $?

add_to_path "$CANONICAL_ID" "$install_path/bin" || exit $?
set_registry "INSTALL_PATH" "$install_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"

if ! command -v java >/dev/null 2>&1; then
    message="Java not found. Apache Maven requires Java; please install it"
    tlog_warn "$tag" "%s" "$message"
    add_message "$CANONICAL_ID" warn "$message"
fi
