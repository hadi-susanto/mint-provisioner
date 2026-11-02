#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/dev/kafka/installer.sh"
source "$LIB_WORKFLOW/stateful-extract-upgrade.sh"

stateful_extract_upgrade \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    --keep "kraft-combined-logs" \
    "bin/kafka-server-start.sh" \
    -- \
    "--strip-components=1" || exit $?

# The new archive ships the default configuration and no wrappers.
install_path="$(get_registry "INSTALL_PATH")" || exit $?
kafka_configure_log_dirs "$CANONICAL_ID" "$install_path" || exit $?
kafka_install_wrappers "$CANONICAL_ID" "$install_path"
