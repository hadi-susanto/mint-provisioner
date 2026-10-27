#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-upgrade.sh"

main "$CANONICAL_ID" "RR" "RustRover"
