#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_LATEST_VERSION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_LATEST_VERSION_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/script.sh"

##
# module_latest_version <canonical_id>
#
# Runs the module's latest.sh to resolve the latest available version.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Output:
#   Prints the latest version.
#
# Return:
#   1 - latest.sh is missing, fails, or prints an invalid version.
#
module_latest_version() {
    local canonical_id="$1"
    local tag="latest:$canonical_id"
    local script="$MP_MODULES/$canonical_id/latest.sh"
    local version

    if [[ ! -f "$script" ]] || [[ -L "$script" ]]; then
        tlog_error "$tag" "Latest-version script not found or invalid: %s" "$script"

        return 1
    fi

    if ! version="$(run_script "$script" "CANONICAL_ID" "$canonical_id")"; then
        tlog_error "$tag" "Failed to resolve the latest version"

        return 1
    fi

    if [[ ! "$version" =~ ^[^[:space:]]+$ ]]; then
        tlog_error "$tag" "latest.sh printed an invalid version: %s" "${version:-<empty>}"

        return 1
    fi

    printf '%s\n' "$version"
}
