#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported install option: %s" "$1"

                return 2
                ;;
            *)
                args_ref+=("$1")
                shift
                ;;
        esac
    done

    return 0
}

__validate_options() {
    local args_name="$1"
    local -n args_ref="$args_name"

    if (( ${#args_ref[@]} == 0 )); then
        log_error "The install command requires at least one module"

        return 2
    fi

    return 0
}

__mock_install_module() {
    local canonical_id="$1"

    tlog_info "install:$canonical_id" "Mock installation completed successfully"

    return 0
}

__process_module() {
    local options_name="$1"
    local canonical_id="$2"
    local result_name="$3"
    local -n options_ref="$options_name"
    local -n result_ref="$result_name"
    local -A metadata=()
    local status

    result_ref="FAILED"

    if ! parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
        tlog_error "install:$canonical_id" "Unable to load module metadata"

        return 1
    fi

    if module_installed "$canonical_id" metadata; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            if (( ! options_ref[FORCE] )); then
                tlog_info "install:$canonical_id" "Already installed; skipping"
                result_ref="SKIPPED"

                return 0
            fi

            tlog_warn "install:$canonical_id" \
                "Already installed; forcing installation"
            ;;
        1)
            tlog_info "install:$canonical_id" "Not installed"
            ;;
        *)
            tlog_error "install:$canonical_id" \
                "Installed-state detection failed (status: %d)" "$status"

            return 1
            ;;
    esac

    __mock_install_module "$canonical_id" || return $?
    result_ref="SUCCESS"

    return 0
}

__run_installation() {
    local options_name="$1"
    local canonical_ids_name="$2"
    local -n canonical_ids_ref="$canonical_ids_name"

    local canonical_id
    local result
    local exit_status=0
    local index
    local -a results=()

    for canonical_id in "${canonical_ids_ref[@]}"; do
        if __process_module "$options_name" "$canonical_id" result; then
            :
        else
            exit_status=1
        fi

        results+=("$result")
    done

    printf 'Installation Results\n'
    printf '%s\n' '===================='

    for (( index = 0; index < ${#canonical_ids_ref[@]}; index += 1 )); do
        printf '%2d. %-30s %s\n' \
            "$((index + 1))" "${canonical_ids_ref[$index]}" "${results[$index]}"
    done

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" install >&2

        return "$status"
    fi

    __validate_options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" install >&2

        return "$status"
    fi

    if (( EUID == 0 )); then
        log_error "Do not run the install command with administrative privileges"

        return 2
    fi

    if ! resolve_module_selectors canonical_ids "${args[@]}"; then
        log_error "Installation aborted because one or more modules could not be resolved"

        return 2
    fi

    __run_installation options canonical_ids
}

main "$@"
