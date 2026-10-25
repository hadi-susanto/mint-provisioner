#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GITHUB_VERSIONING_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GITHUB_VERSIONING_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/registry.sh"

##
# github_recorded_version
#
# Reads the release version recorded in the module registry at install time.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Output:
#   Prints the recorded version.
#
# Return:
#   1 - No registry or no VERSION was recorded.
#   2 - The registry could not be read.
#
github_recorded_version() {
    local canonical_id="$1"
    local status=0

    load_registry "$canonical_id" silent || status=$?
    if (( status != 0 )); then
        return "$status"
    fi

    if ! has_registry "VERSION"; then
        return 1
    fi

    get_registry "VERSION"
}
