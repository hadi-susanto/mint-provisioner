#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_double_commander_package "${DOUBLE_COMMANDER_UI_TOOLKIT:-auto}" || exit $?
save_states "$CANONICAL_ID"
