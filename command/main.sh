#!/usr/bin/env bash
set -euo pipefail

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses the Mint Provisioner command and preserves its arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array that receives command arguments.
#   arguments       Command-line arguments to parse.
#
# Returns:
#   1 when the first parameter is an unsupported option.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [CMD]="help"
    )
    args_ref=()

    if (( $# == 0 )); then
        return 0
    fi

    case "$1" in
        help | -h | --help)
            options_ref[CMD]="help"
            ;;
        -*)
            printf 'Unsupported option: %s\n' "$1" >&2

            return 1
            ;;
        *)
            options_ref[CMD]="$1"
            ;;
    esac

    shift
    args_ref=("$@")
}

main() {
    local -A options=()
    local -a args=()
    local parse_status=0

    __parse_args options args "$@" || parse_status=$?
    if (( parse_status != 0 )); then
        bash "$MP_COMMAND/help.sh" >&2

        return "$parse_status"
    fi

    # Short-circuit an immediate post-command help request.
    if [[ "${options[CMD]}" != "help" ]]; then
        case "${args[0]:-}" in
            help | -h | --help)
                args=("${options[CMD]}")
                options[CMD]="help"
                ;;
        esac
    fi

    case "${options[CMD]}" in
        help)
            exec bash "$MP_COMMAND/help.sh" "${args[@]}"
            ;;
        list)
            exec bash "$MP_COMMAND/list.sh" "${args[@]}"
            ;;
        install)
            exec bash "$MP_COMMAND/install.sh" "${args[@]}"
            ;;
        *)
            printf 'Unsupported command: %s\n\n' "${options[CMD]}" >&2
            bash "$MP_COMMAND/help.sh" >&2

            return 1
            ;;
    esac
}

main "$@"
