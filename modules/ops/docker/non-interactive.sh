#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_docker_lib_install_dir "${DOCKER_LIB_INSTALL_DIR:-${INSTALL_DIR}/docker-lib}" || exit $?
save_states "$CANONICAL_ID"
