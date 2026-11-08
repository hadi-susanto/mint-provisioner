#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${GOCATCLI_EX_INSTALL_DIR:-$INSTALL_DIR/gocatcli-ex}" \
    "gocatcli-ex" \
    "gocatcli-ex" || exit $?
