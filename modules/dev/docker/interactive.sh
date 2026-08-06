#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

__resolve_docker_lib_install_dir() {
    local install_dir="${1:-}"
    local docker_source_dir="/var/lib/docker"

    if [[ "$install_dir" != /* ]]; then
        tlog_error "interactive:$CANONICAL_ID" \
            "Docker data directory must be an absolute path: %s" "$install_dir"

        return 1
    fi

    if [[ "$install_dir" == *'"'* ||
        "$install_dir" == *'\'* ||
        "$install_dir" == *$'\n'* ||
        "$install_dir" == *$'\r'* ]]
    then
        tlog_error "interactive:$CANONICAL_ID" \
            "Docker data directory contains unsupported characters"

        return 1
    fi

    install_dir="$(realpath -m -- "$install_dir")" || {
        tlog_error "interactive:$CANONICAL_ID" \
            "Failed to normalize Docker data directory: %s" "$install_dir"

        return 1
    }

    docker_source_dir="$(realpath -m -- "$docker_source_dir")" || return $?

    if [[ "$install_dir" == "/" ]]; then
        tlog_error "interactive:$CANONICAL_ID" \
            "Docker data directory must not be the filesystem root"

        return 1
    fi

    if [[ "$install_dir" == "$docker_source_dir" ||
        "$install_dir" == "$docker_source_dir/"* ||
        "$docker_source_dir" == "$install_dir/"* ]]
    then
        tlog_error "interactive:$CANONICAL_ID" \
            "Docker data directory must not overlap with %s: %s" \
            "$docker_source_dir" "$install_dir"

        return 1
    fi

    set_state "DOCKER_LIB_INSTALL_DIR" "$install_dir"
    tlog_info "interactive:$CANONICAL_ID" \
        "Docker data directory: %s" "$install_dir"
}

default_install_dir="${DOCKER_LIB_INSTALL_DIR:-${INSTALL_DIR}/docker-lib}"

if [[ "${DOCKER_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_docker_lib_install_dir "$default_install_dir" || exit $?
    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "$LIB_INSTALLER/prompt.sh"

if [[ -n "${DOCKER_LIB_INSTALL_DIR:-}" ]]; then
    selected_install_dir="$DOCKER_LIB_INSTALL_DIR"
else
    selected_install_dir="$(
        ask_text \
            "Where should Docker store images, containers, and volumes?" \
            "$default_install_dir"
    )" || exit $?
fi

__resolve_docker_lib_install_dir "$selected_install_dir" || exit $?
save_states "$CANONICAL_ID" || exit $?
