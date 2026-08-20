#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_brave_browser_channel "${BRAVE_BROWSER_CHANNEL:-release}" || exit $?
save_states "$CANONICAL_ID"
