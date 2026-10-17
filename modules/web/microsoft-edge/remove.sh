#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"

package_remove "$CANONICAL_ID" "microsoft-edge-stable" "microsoft-edge-beta" "microsoft-edge-dev" "microsoft-edge-canary" || exit $?
remove_apt_repository "$CANONICAL_ID"
