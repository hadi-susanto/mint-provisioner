#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"

package_remove "$CANONICAL_ID" "redis" || exit $?
remove_apt_repository "$CANONICAL_ID" || exit $?
