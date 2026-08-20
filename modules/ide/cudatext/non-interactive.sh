#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_cudatext_ui_toolkit "${CUDATEXT_UI_TOOLKIT:-auto}" || exit $?
save_states "$CANONICAL_ID"
