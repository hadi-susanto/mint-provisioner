#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"

package_remove "$CANONICAL_ID" "brave-origin" "brave-origin-beta" "brave-origin-nightly" || exit $?
remove_apt_repository "$CANONICAL_ID" "brave-release" || exit $?
remove_apt_repository "$CANONICAL_ID" "brave-beta" || exit $?
remove_apt_repository "$CANONICAL_ID" "brave-nightly"
