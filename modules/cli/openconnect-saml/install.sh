#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/state.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_WORKFLOW}/pipx-package.sh"
source "${LIB_WORKFLOW}/version-registry.sh"

__ensure_dependencies() {
    local tag="dependency:$CANONICAL_ID"
    local -a packages=(pipx python3-venv libxcb-cursor0)

    if ! command -v openconnect >/dev/null 2>&1; then
        tlog_info "$tag" "openconnect is not installed, installing it as a dependency"
        packages+=(openconnect)
    fi

    if ! apt_install "$CANONICAL_ID" "${packages[@]}"; then
        tlog_error "$tag" "Failed to install dependencies: %s" "${packages[*]}"

        return 1
    fi

    if ! command -v pipx >/dev/null 2>&1; then
        tlog_error "$tag" "pipx is not available after installing its package"

        return 1
    fi
}

main() {
    local raw_install_path="$1"
    local install_path
    local version

    install_path="$(expand_path "$raw_install_path")" || return $?
    load_states "$CANONICAL_ID" || return $?
    version="$(get_state "VERSION")" || return $?
    __ensure_dependencies || return $?
    pipx_package_install "$CANONICAL_ID" "$install_path" "openconnect-saml" "openconnect-saml" "$version" "gui" || return $?
    symlink_binary "$CANONICAL_ID" "$(pipx_package_binary "$install_path" "openconnect-saml" "openconnect-saml")" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$CANONICAL_ID" || return $?
    record_version_registry "$CANONICAL_ID"
}

main "${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
