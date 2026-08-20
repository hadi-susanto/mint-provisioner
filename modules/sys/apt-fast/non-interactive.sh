#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_apt_fast_package_manager "${APT_FAST_PACKAGE_MANAGER:-apt-get}" || exit $?
resolve_apt_fast_max_connection "${APT_FAST_MAX_CONNECTION:-5}" || exit $?
resolve_apt_fast_suppress_confirm_dialog "${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-false}" || exit $?
save_states "$CANONICAL_ID"
