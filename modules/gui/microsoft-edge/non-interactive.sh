#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_microsoft_edge_channel "${MICROSOFT_EDGE_CHANNEL:-stable}" || exit $?
save_states "$CANONICAL_ID"
