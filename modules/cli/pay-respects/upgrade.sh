#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-deb-upgrade.sh"

stateful_deb_upgrade "$CANONICAL_ID" "DEB_FILE"
