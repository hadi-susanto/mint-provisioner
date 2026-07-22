#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

package_installed "$CANONICAL_ID" "brave-origin" "brave-origin-beta" "brave-origin-nightly"
