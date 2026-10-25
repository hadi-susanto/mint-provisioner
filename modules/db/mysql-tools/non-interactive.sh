#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_mysql_tools_connector "${MYSQL_TOOLS_CONNECTOR:-}" || exit $?
save_states "$CANONICAL_ID"
