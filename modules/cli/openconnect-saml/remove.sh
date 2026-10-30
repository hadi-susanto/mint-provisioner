#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_REMOVER/binary.sh"
source "$LIB_WORKFLOW/pipx-package.sh"

remove_symlink "$CANONICAL_ID" "openconnect-saml" || exit $?

# INSTALL_PATH is a pipx home shared with other modules, so only this package is uninstalled.
if load_registry "$CANONICAL_ID" silent && install_path="$(get_registry "INSTALL_PATH")"; then
    pipx_package_uninstall "$CANONICAL_ID" "$install_path" "openconnect-saml" || exit $?
fi
