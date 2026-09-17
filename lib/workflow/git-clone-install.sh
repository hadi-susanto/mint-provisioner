#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GIT_CLONE_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GIT_CLONE_INSTALL_LOADED=1

source "$LIB_INSTALLER/git-clone.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"

git_clone_install() {
    local canonical_id="$1"
    local git_url="$2"
    local raw_install_path="$3"
    local install_path

    shift 3

    install_path="$(expand_path "$raw_install_path")" || return $?
    git_clone "$canonical_id" "$git_url" "$install_path" "$@" || return $?

    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?

    tlog_info "git-clone:$canonical_id" "Installation completed successfully"
}
