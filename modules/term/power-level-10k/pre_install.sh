#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/install-target.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path

    if ! command -v git >/dev/null 2>&1; then
        tlog_error "pre-install:$canonical_id" "git is required but not installed"

        return 1
    fi

    install_path="$(resolve_install_target "$canonical_id" "$raw_install_path")" || return $?
}

main "$CANONICAL_ID" "${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"
