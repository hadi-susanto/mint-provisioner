#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_JETBRAINS_LATEST_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_JETBRAINS_LATEST_LOADED=1

source "$LIB_WORKFLOW/jetbrains-release.sh"

##
# main <canonical_id> <release_code>
#
# Entry point for JetBrains latest.sh scripts.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   release_code - JetBrains product release code, such as IIU.
#
# Output:
#   Prints the latest release version.
#
# Return:
#   Non-zero when the release could not be resolved.
#
main() {
    local canonical_id="$1"
    local release_code="$2"
    local -A release=()

    jetbrains_latest_release "$canonical_id" "$release_code" release || return $?
    printf '%s\n' "${release[VERSION]}"
}
