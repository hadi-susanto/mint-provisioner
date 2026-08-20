#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DOCKER_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DOCKER_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/state.sh"

resolve_docker_lib_install_dir() {
    local raw_install_path="$1"
    local docker_source_dir="/var/lib/docker"
    local tag="lib-dir:$CANONICAL_ID"
    local install_path

    install_path="$(expand_path "$raw_install_path")" || return $?

    if [[ "$install_path" == "/" ]]; then
        tlog_error "$tag" \
            "Docker data directory must not be the filesystem root"

        return 1
    fi

    if [[ "$install_path" == "$docker_source_dir" ||
        "$install_path" == "$docker_source_dir/"* ||
        "$docker_source_dir" == "$install_path/"* ]]
    then
        tlog_error "$tag" \
            "Docker data directory must not overlap with %s: %s" \
            "$docker_source_dir" "$install_path"

        return 1
    fi

    set_state "DOCKER_LIB_INSTALL_DIR" "$install_path"
    tlog_info "$tag" "Docker data directory: %s" "$install_path"
}