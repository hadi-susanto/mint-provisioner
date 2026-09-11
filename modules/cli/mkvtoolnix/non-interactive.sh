#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_mkvtoolnix_gui_enabled "${MKVTOOLNIX_GUI_ENABLED:-false}" || exit $?
save_states "$CANONICAL_ID"
