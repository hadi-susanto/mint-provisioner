#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/dev/kafka/installer.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"

install_dir="${KAFKA_INSTALL_DIR:-$INSTALL_DIR/kafka}"

valid_install_target "$CANONICAL_ID" "$install_dir" "KAFKA_INSTALL_DIR" || exit $?
version="$(module_latest_version "$CANONICAL_ID")" || exit $?

kafka_download_archive "$CANONICAL_ID" "$version"
