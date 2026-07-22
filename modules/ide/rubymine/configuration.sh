#!/usr/bin/env bash
set -euo pipefail

source "${MODULES_DIR}/ide/jetbrains.sh"
source "${LIB_DIR}/state.sh"

if command -v jq >/dev/null 2>&1; then
    log_info "[$CANONICAL_ID] jq is already available"
    auto_install_jq="false"
elif [[ -n "${JETBRAINS_AUTO_INSTALL_JQ+x}" ]]; then
    auto_install_jq="$(
        jetbrains_resolve_auto_install_jq \
            "$CANONICAL_ID" \
            "$JETBRAINS_AUTO_INSTALL_JQ"
    )" || exit $?
elif [[ "${RUBYMINE_NON_INTERACTIVE:-${JETBRAINS_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}}" == "true" ]]; then
    auto_install_jq="$(
        jetbrains_resolve_auto_install_jq "$CANONICAL_ID" "false"
    )" || exit $?
else
    auto_install_jq="$(
        jetbrains_prompt_auto_install_jq "$CANONICAL_ID"
    )" || exit $?
fi

if command -v aria2c >/dev/null 2>&1; then
    log_info "[$CANONICAL_ID] aria2c is already available"
    auto_install_aria2="false"
elif [[ -n "${JETBRAINS_AUTO_INSTALL_ARIA2+x}" ]]; then
    auto_install_aria2="$(
        jetbrains_resolve_auto_install_aria2 \
            "$CANONICAL_ID" \
            "$JETBRAINS_AUTO_INSTALL_ARIA2"
    )" || exit $?
elif [[ "${RUBYMINE_NON_INTERACTIVE:-${JETBRAINS_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}}" == "true" ]]; then
    auto_install_aria2="$(
        jetbrains_resolve_auto_install_aria2 "$CANONICAL_ID" "false"
    )" || exit $?
else
    auto_install_aria2="$(
        jetbrains_prompt_auto_install_aria2 "$CANONICAL_ID"
    )" || exit $?
fi

set_state "JETBRAINS_AUTO_INSTALL_JQ" "$auto_install_jq" || exit $?
set_state "JETBRAINS_AUTO_INSTALL_ARIA2" "$auto_install_aria2" || exit $?
save_states "$CANONICAL_ID" || exit $?
