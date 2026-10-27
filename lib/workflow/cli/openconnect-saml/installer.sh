#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_OPENCONNECT_SAML_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_OPENCONNECT_SAML_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# openconnect_saml_binary <install_path>
#
# Parameters:
#   install_path - pipx home (PIPX_HOME).
#
# Output:
#   Prints the openconnect-saml executable path inside the pipx home.
#
openconnect_saml_binary() {
    printf '%s\n' "$1/venvs/openconnect-saml/bin/openconnect-saml"
}

##
# openconnect_saml_install_pipx <canonical_id> <install_path> <version>
#
# Installs or replaces openconnect-saml with pipx (pipx install --force) in the
# pipx home install_path. Other venvs in the pipx home are not touched.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   install_path - pipx home (PIPX_HOME).
#   version - openconnect-saml version to install.
#
# Return:
#   1 - The directory could not be created, pipx failed, or the executable is missing.
#
openconnect_saml_install_pipx() {
    local canonical_id="$1"
    local install_path="$2"
    local version="$3"
    local tag="pipx:$canonical_id"
    local binary

    binary="$(openconnect_saml_binary "$install_path")"

    if ! mkdir -p "$install_path"; then
        tlog_error "$tag" "Failed to create installation directory: %s" "$install_path"

        return 1
    fi

    tlog_info "$tag" "Installing openconnect-saml %s with pipx into %s" "$version" "$install_path"
    if ! PIPX_HOME="$install_path" pipx install --force "openconnect-saml[gui]==$version"; then
        tlog_error "$tag" "pipx failed to install openconnect-saml"

        return 1
    fi

    if [[ ! -x "$binary" ]]; then
        tlog_error "$tag" "Expected executable not found: %s" "$binary"

        return 1
    fi
}
