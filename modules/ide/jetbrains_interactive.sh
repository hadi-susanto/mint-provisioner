#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_INTERACTIVE_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_INTERACTIVE_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

__resolve() {
    local tag="$1"
    local cli="$2"
    local env_value="$3"

    if command -v "$cli" >/dev/null 2>&1; then
        tlog_info "$tag" "%s is already available" "$cli"
        printf "false\n"

        return 0
    fi
    
    case "$env_value" in
        true)
            tlog_info "$tag" "Proceeding with %s installation" "$cli"
            printf "true\n"
            ;;
        false)
            tlog_info "$tag" "User declined %s installation. Skipping" "$cli"
            printf "false\n"
            ;;
        "")
            tlog_warn "$tag" "No explicit user consent, default to skip %s installation" "$cli"
            printf "false\n"
            ;;
        *)
            tlog_error "$tag" "Invalid %s value: %s. Expected true or false." 

            return 1
            ;;
    esac
}

__interactive() {
    local tag="$1"
    local cli="$2"
    local env_value="$3"
    local question="$4"

    if [[ -n "$env_value" ]]; then
        printf "%s\n" "$(__resolve "$tag" "$cli" "$env_value")" || return $?

        return 0
    fi
    
    source "$LIB_INSTALLER/prompt.sh"
    local selected_index

    selected_index="$(
        choose_option \
            "$question" \
            "Yes, install $cli when required" \
            "No, do not install $cli"
    )" || return $?

    case "$selected_index" in
        0)
            tlog_info "$tag" "Proceeding with %s installation" "$cli"
            printf "true\n"
            ;;
        1)
            tlog_info "$tag" "User declined %s installation. Skipping" "$cli"
            printf "false\n"
            ;;
        *)
            tlog_error "$tag" "Unexpected %s installation selection index: %s" \
                "$cli" "$selected_index"

            return 1
            ;;
    esac
}

main() {
    local canonical_id="$1"
    local non_interactive="$2"
    local auto_jq_env="$3"
    local auto_aria2c_env="$4"
    local tag="interactive:$canonical_id"
    local resolved_auto_jq
    local resolved_auto_aria2c
    
    if [[ "$non_interactive" == "true" ]]; then
        resolved_auto_jq="$(__resolve "$tag" "jq" "$auto_jq_env")" || return $?
        resolved_auto_aria2c="$(__resolve "$tag" "aria2c" "$auto_aria2c_env")" || return $?
    else
        local question

        question="jq is required to read JetBrains release metadata. May Mint Provisioner install jq automatically if it is missing?"
        resolved_auto_jq="$(__interactive "$tag" "jq" "$auto_jq_env" "$question")" || return $?

        question="aria2 can accelerate JetBrains archive downloads. May Mint Provisioner install aria2 automatically if it is missing?"
        resolved_auto_aria2c="$(__interactive "$tag" "aria2c" "$auto_aria2c_env" "$question")" || return $?
    fi
    
    set_state "JETBRAINS_AUTO_INSTALL_JQ" "$resolved_auto_jq"
    set_state "JETBRAINS_AUTO_INSTALL_ARIA2" "$resolved_auto_aria2c"
    save_states "$canonical_id"
}