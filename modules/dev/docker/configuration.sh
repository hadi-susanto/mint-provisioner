#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__set_docker_lib_install_dir() {
    local install_dir="$1"

    if [[ "$install_dir" != /* ]]; then
        log_error \
            "[$CANONICAL_ID] Docker library installation directory must be an absolute path: $install_dir"

        return 1
    fi

    if [[ "$install_dir" == "/" ]]; then
        log_error \
            "[$CANONICAL_ID] Docker library installation directory must not be the filesystem root"

        return 1
    fi

    if [[ "$install_dir" == "/var/lib/docker" ]]; then
        log_error \
            "[$CANONICAL_ID] Docker library installation directory must differ from /var/lib/docker"

        return 1
    fi

    if [[ "$install_dir" == *'"'* ||
        "$install_dir" == *'\'* ||
        "$install_dir" == *$'\n'* ]]
    then
        log_error \
            "[$CANONICAL_ID] Docker library installation directory contains unsupported characters"

        return 1
    fi

    #
    # Remove trailing slashes while preserving the absolute path.
    #
    while [[ "$install_dir" != "/" && "$install_dir" == */ ]]; do
        install_dir="${install_dir%/}"
    done

    set_state "DOCKER_LIB_INSTALL_DIR" "$install_dir"

    log_info \
        "[$CANONICAL_ID] Docker library installation directory: $install_dir"

    return 0
}

default_install_dir="${DOCKER_LIB_INSTALL_DIR:-${INSTALL_DIR}/docker-lib}"

if [[ "${DOCKER_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __set_docker_lib_install_dir "$default_install_dir" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

if [[ -n "${DOCKER_LIB_INSTALL_DIR:-}" ]]; then
    selected_install_dir="$DOCKER_LIB_INSTALL_DIR"
else
    selected_install_dir="$(
        ask_text \
            "Directory used to store Docker images, containers, and volumes" \
            "$default_install_dir"
    )" || exit $?
fi

__set_docker_lib_install_dir "$selected_install_dir" || exit $?

save_states "$CANONICAL_ID" || exit $?

exit 0
