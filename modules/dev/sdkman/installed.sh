#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"

main() {
    local canonical_id="$1"
    local install_path="$2"

    if [[ -n "$install_path" ]]; then
        [[ -f "$install_path/bin/sdkman-init.sh" ]]

        return $?
    fi

    # Fortunately, when no state file it will return 1, match our contract
    # for installed should return 1 for not installed, > 1 for error
    load_registry "$canonical_id" || return $?
    install_path="$(get_registry "INSTALL_PATH" 2>/dev/null)" || return 2

    [[ -f "$install_path/bin/sdkman-init.sh" ]]
}

main "$CANONICAL_ID" "${SDKMAN_INSTALL_DIR:-}"
