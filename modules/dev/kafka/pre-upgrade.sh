#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/dev/kafka/installer.sh"
source "$LIB_WORKFLOW/latest-version.sh"

version="$(module_latest_version "$CANONICAL_ID")" || exit $?

kafka_download_archive "$CANONICAL_ID" "$version"
