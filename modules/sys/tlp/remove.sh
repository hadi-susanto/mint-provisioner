#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"

package_remove "$CANONICAL_ID" "tlp" "tlp-rdw"
