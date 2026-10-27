#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"

tag="upgrade:$CANONICAL_ID"

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

if [[ ! -f "$install_path/bin/sdkman-init.sh" ]]; then
    tlog_error "$tag" "SDKMAN! init script not found: %s" "$install_path/bin/sdkman-init.sh"

    exit 1
fi

# SDKMAN! updates itself and keeps candidates/ and etc/config. sdkman-init.sh is
# not written for strict mode, so it runs in a separate shell without it.
tlog_info "$tag" "Running sdk selfupdate force in %s" "$install_path"
if ! SDKMAN_DIR="$install_path" bash -c \
    'source "$SDKMAN_DIR/bin/sdkman-init.sh" && sdk selfupdate force' </dev/null; then
    tlog_error "$tag" "sdk selfupdate failed"

    exit 1
fi

if ! version="$(<"$install_path/var/version")"; then
    tlog_error "$tag" "Failed to read the upgraded SDKMAN! version"

    exit 1
fi

set_registry "VERSION" "${version//[[:space:]]/}" || exit $?
if [[ -f "$install_path/var/version_native" ]]; then
    native_version="$(<"$install_path/var/version_native")"
    set_registry "SDKMAN_NATIVE_VERSION" "${native_version//[[:space:]]/}" || exit $?
fi

save_registry "$CANONICAL_ID" || exit $?
tlog_info "$tag" "Recorded installed version: %s" "${version//[[:space:]]/}"
