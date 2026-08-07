#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_cleanup.sh"

main "$CANONICAL_ID"
