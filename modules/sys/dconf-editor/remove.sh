#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"

package_remove "$CANONICAL_ID" "dconf-editor"
