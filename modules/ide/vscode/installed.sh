#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

package_installed "$CANONICAL_ID" "code" "code-insiders"
