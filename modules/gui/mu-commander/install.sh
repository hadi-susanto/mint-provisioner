#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE"
