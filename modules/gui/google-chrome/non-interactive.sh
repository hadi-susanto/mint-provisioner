#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_google_chrome_channel "${GOOGLE_CHROME_CHANNEL:-stable}" || exit $?
save_states "$CANONICAL_ID"
