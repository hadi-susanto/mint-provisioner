#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

docker_lib_install_dir="${DOCKER_LIB_INSTALL_DIR:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$docker_lib_install_dir" ]]; then
    if resolve_docker_lib_install_dir "$docker_lib_install_dir"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid DOCKER_LIB_INSTALL_DIR value."
fi

source "$LIB_INSTALLER/prompt.sh"

docker_lib_install_dir="$(
    ask_text \
        "Where should Docker store images, containers, and volumes?" \
        "$INSTALL_DIR/docker-lib"
)" || exit $?

resolve_docker_lib_install_dir "$docker_lib_install_dir" || exit $?

save_states "$CANONICAL_ID"
