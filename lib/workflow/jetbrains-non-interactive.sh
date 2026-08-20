#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_NON_INTERACTIVE_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_NON_INTERACTIVE_LOADED=1

source "$LIB_WORKFLOW/jetbrains-cli-resolver.sh"

main() {
    if ! command -v "jq" >/dev/null 2>&1; then
        resolve_jq_auto_install "$CANONICAL_ID" "${JETBRAINS_AUTO_INSTALL_JQ:-false}" || return $?
    fi

    if ! command -v "aria2c" >/dev/null 2>&1; then
        resolve_aria2_auto_install "$CANONICAL_ID" "${JETBRAINS_AUTO_INSTALL_ARIA2:-false}" || return $?
    fi

    save_states "$CANONICAL_ID"
}