#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/symlink.sh"

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

__pipx_binary() {
    printf '%s\n' "$1/venvs/openconnect-saml/bin/openconnect-saml"
}

__install_with_pipx() {
    local install_path="$1"
    local tag="pipx:$CANONICAL_ID"

    if ! mkdir -p "$install_path"; then
        tlog_error "$tag" "Failed to create installation directory: %s" "$install_path"

        return 1
    fi

    tlog_info "$tag" "Installing openconnect-saml with pipx into %s" "$install_path"
    if ! PIPX_HOME="$install_path" pipx install --force "openconnect-saml[gui]"; then
        tlog_error "$tag" "pipx failed to install openconnect-saml"

        return 1
    fi

    if [[ ! -x "$(__pipx_binary "$install_path")" ]]; then
        tlog_error "$tag" "Expected executable not found: %s" "$(__pipx_binary "$install_path")"

        return 1
    fi
}

main() {
    local raw_install_path="$1"
    local install_path

    install_path="$(expand_path "$raw_install_path")" || return $?
    __ensure_dependencies || return $?
    __install_with_pipx "$install_path" || return $?
    symlink_binary "$CANONICAL_ID" "$(__pipx_binary "$install_path")" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$CANONICAL_ID"
}

main "${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
