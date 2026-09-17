#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_vscode_channel "${VSCODE_CHANNEL:-stable}" || exit $?
save_states "$CANONICAL_ID"
