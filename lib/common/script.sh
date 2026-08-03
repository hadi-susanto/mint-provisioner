#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_SCRIPT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_SCRIPT_LOADED=1

source "$LIB_COMMON/common.sh"

##
# run_script
#
# Executes a script directly when executable or through Bash otherwise.
#
# Parameters:
#   file        - Script file to execute.
#   environment - Optional variable-name/value pairs supplied to the script.
#                 A name without a value receives an empty value.
#
# Returns:
#   1 when the file or an environment-variable name is invalid; otherwise the
#   executed script's status.
#
run_script() {
    local file="${1:-}"
    local key
    local value
    local -a environment=()

    if [[ -z "$file" ]]; then
        tlog_error "script" "A script file is required"

        return 1
    fi

    shift

    if [[ ! -f "$file" ]]; then
        tlog_error "script" "Script file not found: %s" "$file"

        return 1
    fi

    while (( $# > 0 )); do
        key="$1"
        shift

        if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            tlog_error "script" "Invalid environment variable name: %s" "$key"

            return 1
        fi

        value=""
        if (( $# > 0 )); then
            value="$1"
            shift
        fi

        environment+=("$key=$value")
    done

    if [[ -x "$file" ]]; then
        env "${environment[@]}" "$file"
    else
        env "${environment[@]}" bash "$file"
    fi
}
