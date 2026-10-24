#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/install-plan.sh"
source "$LIB_COMMON/resolver.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
        [HELP]=0
        [NON_INTERACTIVE]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;
            -ni | --non-interactive | --unattended)
                options_ref[NON_INTERACTIVE]=1
                shift
                ;;
            -h | --help)
                options_ref[HELP]=1
                shift
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported plan option: %s" "$1"

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
        log_error "The plan command requires at least one module"

        return 2
    fi

    return 0
}

##
# __plan_row <non_interactive> <canonical_id> <action> <row_name>
#
# Fills the PHASES and NOTES columns of one plan row and marks the row
# blocked when non-interactive mode is selected but unsupported.
#
__plan_row() {
    local non_interactive="$1"
    local canonical_id="$2"
    local action="$3"
    local -n row_ref="$4"
    local module_dir="$MP_MODULES/$canonical_id"
    local -a phases=()
    local -a notes=()
    local -a install_phases=()
    local joined

    row_ref=(
        [ACTION]="$action"
        [PHASES]="-"
        [NOTES]=""
    )

    case "$action" in
        error)
            row_ref[NOTES]="detection failed"

            return 0
            ;;
        skip)
            row_ref[NOTES]="already installed"

            return 0
            ;;
        reinstall)
            notes+=("already installed")
            ;;
    esac

    if (( non_interactive )) && ! module_supports_non_interactive "$canonical_id"; then
        row_ref[ACTION]="blocked"
        notes+=("no non-interactive support")
    elif (( non_interactive )) && [[ -e "$module_dir/non-interactive.sh" ]]; then
        phases+=("non-interactive")
    elif [[ -e "$module_dir/interactive.sh" ]]; then
        phases+=("interactive")
        notes+=("prompts")
    fi

    list_install_phases "$canonical_id" install_phases
    phases+=("${install_phases[@]}")

    joined=$(printf '%s,' "${phases[@]}")
    row_ref[PHASES]="${joined%,}"

    if (( ${#notes[@]} > 0 )); then
        joined=$(printf '%s; ' "${notes[@]}")
        row_ref[NOTES]="${joined%; }"
    fi

    return 0
}

##
# __print_plan <non_interactive> <canonical_id...>
#
# Prints the plan table and summary for each unique canonical ID.
#
# Return:
#   1 when a module failed detection or is blocked.
#
__print_plan() {
    local non_interactive="$1"
    shift

    local canonical_id
    local action
    local index
    local failed=0
    local module_width=6
    local source_width=6
    local phases_width=6
    local -A seen=()
    local -A row=()
    local -A counts=(
        [install]=0
        [reinstall]=0
        [skip]=0
        [blocked]=0
        [error]=0
    )
    local -a ids=()
    local -a actions=()
    local -a phases=()
    local -a notes=()
    local source
    local color
    local color_reset

    for canonical_id in "$@"; do
        if [[ -n "${seen[$canonical_id]:-}" ]]; then
            continue
        fi

        seen["$canonical_id"]=1
        __plan_row "$non_interactive" "$canonical_id" \
            "${INSTALL_PLAN_ACTIONS[$canonical_id]:-error}" row

        ids+=("$canonical_id")
        actions+=("${row[ACTION]}")
        phases+=("${row[PHASES]}")
        notes+=("${row[NOTES]}")
        counts["${row[ACTION]}"]=$(( counts["${row[ACTION]}"] + 1 ))

        if (( ${#canonical_id} > module_width )); then
            module_width=${#canonical_id}
        fi

        source="${INSTALL_PLAN_SOURCES[$canonical_id]:-}"
        if (( ${#source} > source_width )); then
            source_width=${#source}
        fi

        if (( ${#row[PHASES]} > phases_width )); then
            phases_width=${#row[PHASES]}
        fi
    done

    printf '%-9s  %-*s  %-*s  %-*s  %s\n' "ACTION" \
        "$module_width" "MODULE" "$source_width" "SOURCE" \
        "$phases_width" "PHASES" "NOTES"

    for index in "${!ids[@]}"; do
        canonical_id="${ids[$index]}"
        action="${actions[$index]}"
        color=""
        color_reset=""

        # Highlight forced reinstalls and skipped modules.
        case "$action" in
            reinstall)
                color="$COLOR_YELLOW"
                color_reset="$COLOR_RESET"
                ;;
            skip)
                color="$COLOR_CYAN"
                color_reset="$COLOR_RESET"
                ;;
        esac

        printf '%s%-9s  %-*s  %-*s  %-*s  %s%s\n' "$color" "$action" \
            "$module_width" "$canonical_id" \
            "$source_width" "${INSTALL_PLAN_SOURCES[$canonical_id]:--}" \
            "$phases_width" "${phases[$index]}" "${notes[$index]}" "$color_reset"
    done

    printf '\n%d to install, %d to reinstall, %d skipped' \
        "${counts[install]}" "${counts[reinstall]}" "${counts[skip]}"

    if (( counts[blocked] > 0 )); then
        printf ', %d blocked' "${counts[blocked]}"
        failed=1
    fi

    if (( counts[error] > 0 )); then
        printf ', %d failed detection' "${counts[error]}"
        failed=1
    fi

    printf '\n'

    return "$failed"
}

##
# __confirm_install
#
# Asks whether to continue with the installation. The plain-bash prompt is
# forced so the question appears below the plan instead of hiding it behind a
# whiptail dialog.
#
# Return:
#   0 - The user answered yes.
#   1 - The user answered no.
#   2 - No terminal is available or the answer could not be read.
#
__confirm_install() {
    local DISABLE_WHIPTAIL=true

    if ! source "$LIB_INSTALLER/prompt.sh"; then
        return 2
    fi

    printf '\n'
    ask_confirm "Continue with installation?"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a install_args=()
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" plan >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" plan

        return 0
    fi

    __validate_options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" plan >&2

        return "$status"
    fi

    if (( EUID == 0 )); then
        log_error "Do not run 'mp plan' with sudo or as root"
        log_error "Installed-state detection would inspect root's \$HOME instead of yours"

        return 2
    fi

    if ! resolve_module_selectors canonical_ids "${args[@]}"; then
        log_error "Planning aborted because one or more modules could not be resolved"

        return 2
    fi

    plan_install_modules "${options[FORCE]}" "${canonical_ids[@]}" || status=$?
    if (( status > 1 )); then
        return "$status"
    fi

    __print_plan "${options[NON_INTERACTIVE]}" "${canonical_ids[@]}" || return $?

    # Only offer to install when a person is at the terminal and there is work to do.
    if (( ${#INSTALL_PLAN_QUEUE[@]} == 0 )) || [[ ! -t 0 || ! -t 1 ]]; then
        return 0
    fi

    status=0
    __confirm_install || status=$?
    if (( status == 1 )); then
        log_info "Installation not started."

        return 0
    fi

    if (( status != 0 )); then
        log_error "Installation not started: the confirmation could not be read"

        return 1
    fi

    if (( options[FORCE] )); then
        install_args+=(--force)
    fi

    if (( options[NON_INTERACTIVE] )); then
        install_args+=(--non-interactive)
    fi

    exec bash "$MP_COMMAND/install.sh" "${install_args[@]}" -- "${canonical_ids[@]}"
}

main "$@"
