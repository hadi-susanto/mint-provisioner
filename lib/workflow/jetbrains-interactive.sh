#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_INTERACTIVE_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_INTERACTIVE_LOADED=1

source "$LIB_WORKFLOW/jetbrains-cli-resolver.sh"

__process_jq() {
    local auto_install="${JETBRAINS_AUTO_INSTALL_JQ:-}"
    local tag="jq-auto:$CANONICAL_ID"

    if [[ -n "$auto_install" ]]; then
        if resolve_jq_auto_install "$CANONICAL_ID" "$auto_install"; then
            return 0
        fi

        tlog_warn "$tag" "Fallback to interactive session: invalid JETBRAINS_AUTO_INSTALL_JQ value."
    fi

    source "$LIB_INSTALLER/prompt.sh"
    local selected_index

    selected_index="$(
        choose_option \
            "jq is required to read JetBrains release metadata. May Mint Provisioner install jq automatically?" \
            "Yes, install jq" \
            "No, do not install jq"
    )" || return $?

    case "$selected_index" in
        0)
            resolve_jq_auto_install "$CANONICAL_ID" "true"
            ;;
        1)
            resolve_jq_auto_install "$CANONICAL_ID" "false"
            ;;
        *)
            tlog_error "$tag" "Unexpected jq installation selection index: %s" "$selected_index"

            return 1
            ;;
    esac
}

__process_aria2() {
    local auto_install="${JETBRAINS_AUTO_INSTALL_ARIA2:-}"
    local tag="aria2-auto:$CANONICAL_ID"

    if [[ -n "$auto_install" ]]; then
        if resolve_aria2_auto_install "$CANONICAL_ID" "$auto_install"; then
            return 0
        fi

        tlog_warn "$tag" "Fallback to interactive session: invalid JETBRAINS_AUTO_INSTALL_ARIA2 value."
    fi

    source "$LIB_INSTALLER/prompt.sh"
    local selected_index

    selected_index="$(
        choose_option \
            "aria2 can accelerate JetBrains archive downloads. May Mint Provisioner install aria2 automatically?" \
            "Yes, install aria2" \
            "No, do not install aria2"
    )" || return $?

    case "$selected_index" in
        0)
            resolve_aria2_auto_install "$CANONICAL_ID" "true"
            ;;
        1)
            resolve_aria2_auto_install "$CANONICAL_ID" "false"
            ;;
        *)
            tlog_error "$tag" "Unexpected aria installation selection index: %s" "$selected_index"

            return 1
            ;;
    esac
}

main() {
    if ! command -v "jq" >/dev/null 2>&1; then
        __process_jq || return $?
    fi

    if ! command -v "aria2c" >/dev/null 2>&1; then
        __process_aria2 || return $?
    fi

    save_states "$CANONICAL_ID"
}