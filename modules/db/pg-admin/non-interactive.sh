#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_pgadmin_package "${PGADMIN_UI:-desktop}" || exit $?
save_states "$CANONICAL_ID"