#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_VERSION_REGISTRY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_VERSION_REGISTRY_LOADED=1

source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

##
# record_version_registry <canonical_id>
#
# Copies the loaded VERSION state into the module registry, keeping existing
# registry values. Does nothing when no VERSION state exists. Failures only log
# a warning because a missing version must not fail the installation.
#
# Parameters:
#   canonical_id - Canonical module ID whose states are already loaded.
#
record_version_registry() {
    local canonical_id="$1"
    local tag="version:$canonical_id"
    local version
    local status=0

    if ! has_state "VERSION"; then
        return 0
    fi

    version="$(get_state "VERSION")" || return 0

    load_registry "$canonical_id" silent || status=$?
    if (( status > 1 )); then
        tlog_warn "$tag" "Skipping version record; the registry could not be loaded"

        return 0
    fi

    if ! set_registry "VERSION" "$version" || ! save_registry "$canonical_id"; then
        tlog_warn "$tag" "Failed to record installed version: %s" "$version"

        return 0
    fi

    tlog_info "$tag" "Recorded installed version: %s" "$version"
}
