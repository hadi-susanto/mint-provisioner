#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"

__parse_args() {
    local options_name="$1"
    local categories_name="$2"
    local args_name="$3"
    shift 3

    local -n options_ref="$options_name"
    local -n categories_ref="$categories_name"
    local -n args_ref="$args_name"

    options_ref=(
        [STATUS]="all"
    )
    categories_ref=()
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -c | --category)
                if (( $# < 2 )) || [[ "$2" == -* ]]; then
                    log_error "Option %s requires a category" "$1"

                    return 2
                fi

                categories_ref+=("$2")
                shift 2
                ;;
            -s | --status)
                if (( $# < 2 )) || [[ "$2" == -* ]]; then
                    log_error "Option %s requires a status" "$1"

                    return 2
                fi

                options_ref[STATUS]="$2"
                shift 2
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported list option: %s" "$1"

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
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    if (( ${#args_ref[@]} != 1 )); then
        log_error "The list command requires exactly one target: category or modules"

        return 2
    fi

    case "${args_ref[0]}" in
        category | modules)
            ;;
        *)
            log_error "Unsupported list target '%s'; supported targets: category, modules" \
                "${args_ref[0]}"

            return 2
            ;;
    esac

    if [[ "${options_ref[STATUS]}" != "all" ]]; then
        log_error "Unsupported list status '%s'; supported status: all" \
            "${options_ref[STATUS]}"

        return 2
    fi

    return 0
}

__select_categories() {
    local selected_name="$1"
    shift

    local -n selected_ref="$selected_name"
    local -a available_categories=()
    local -A category_flags=()
    local category
    local invalid=0

    selected_ref=()
    list_categories available_categories

    if (( $# == 0 )); then
        selected_ref=("${available_categories[@]}")

        return 0
    fi

    # Build a lookup table for available categories.
    for category in "${available_categories[@]}"; do
        category_flags["$category"]=0
    done

    # Validate and mark requested categories.
    for category in "$@"; do
        if [[ -v "category_flags[$category]" ]]; then
            category_flags["$category"]=1

            continue
        fi

        invalid=1
        log_error "Unsupported category filter: %s" "$category"
    done

    if (( invalid )); then
        return 2
    fi

    # Select categories using the canonical available-category order.
    for category in "${available_categories[@]}"; do
        if (( category_flags["$category"] )); then
            selected_ref+=("$category")
        fi
    done

    return 0
}

__load_category_metadata() {
    local names_name="$1"
    local descriptions_name="$2"
    shift 2

    local -n names_ref="$names_name"
    local -n descriptions_ref="$descriptions_name"
    local -A metadata=()
    local category_id

    names_ref=()
    descriptions_ref=()

    for category_id in "$@"; do
        parse_category_metadata "$MP_MODULES/$category_id" metadata || return $?

        names_ref["$category_id"]="${metadata[NAME]}"
        descriptions_ref["$category_id"]="${metadata[DESCRIPTION]}"
    done

    return 0
}

__print_categories() {
    local -A names=()
    local -A descriptions=()
    local category_id
    local index=1

    __load_category_metadata names descriptions "$@" || return $?

    printf 'Mint Provisioner Supported Categories\n'
    printf '%s\n' '====================================='

    if (( $# == 0 )); then
        printf 'No supported categories.\n'

        return 0
    fi

    for category_id in "$@"; do
        printf '%2d. %b%s%b %b[id: %s]%b\n' \
            "$index" \
            "$COLOR_CYAN" "${names[$category_id]}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$category_id" "$COLOR_RESET"
        printf '    %s\n' "${descriptions[$category_id]}"

        ((index += 1))
    done

    return 0
}

__load_module_metadata() {
    local names_name="$1"
    local descriptions_name="$2"
    shift 2

    local -n names_ref="$names_name"
    local -n descriptions_ref="$descriptions_name"
    local -A metadata=()
    local canonical_id

    names_ref=()
    descriptions_ref=()

    for canonical_id in "$@"; do
        parse_module_metadata "$MP_MODULES/$canonical_id" metadata || return $?

        names_ref["$canonical_id"]="${metadata[NAME]}"
        descriptions_ref["$canonical_id"]="${metadata[DESCRIPTION]}"
    done

    return 0
}

__print_modules() {
    local -a modules=()
    local -A category_names=()
    local -A _category_descriptions=()
    local -A module_names=()
    local -A module_descriptions=()
    local -A printed_categories=()
    local canonical_id
    local category_id
    local previous_category_id=""
    local requested_category
    local index=0

    list_modules modules "$@" || return $?
    __load_category_metadata \
        category_names _category_descriptions "$@" || return $?
    __load_module_metadata \
        module_names module_descriptions "${modules[@]}" || return $?

    printf 'Mint Provisioner Supported Modules\n'
    printf '==================================='
    if (( ${#modules[@]} == 0 )); then
        printf '\nNo supported modules.\n'

        return 0
    fi

    for canonical_id in "${modules[@]}"; do
        category_id="${canonical_id%%/*}"

        if [[ "$category_id" != "$previous_category_id" ]]; then
            printf '\n%b%s%b %b[id: %s]%b\n' \
                "$COLOR_GREEN" "${category_names[$category_id]}" "$COLOR_RESET" \
                "$COLOR_YELLOW" "$category_id" "$COLOR_RESET"
            printf '%s\n' '-----------------------------------'

            printed_categories["$category_id"]=1
            previous_category_id="$category_id"
            index=1
        fi

        printf '%2d. %b%s%b %b[id: %s]%b\n' \
            "$index" \
            "$COLOR_CYAN" "${module_names[$canonical_id]}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
        printf '    %s\n' "${module_descriptions[$canonical_id]}"

        ((index += 1))
    done

    for requested_category in "$@"; do
        if [[ -v "printed_categories[$requested_category]" ]]; then
            continue
        fi

        printf '\n%b%s%b %b[id: %s]%b\n' \
            "$COLOR_GREEN" "${category_names[$requested_category]}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$requested_category" "$COLOR_RESET"
        printf 'No supported modules.\n'
    done

    return 0
}

main() {
    local -A options=()
    local -a requested_categories=()
    local -a selected_categories=()
    local -a args=()
    local status=0

    __parse_args options requested_categories args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" list >&2

        return "$status"
    fi

    __validate_options options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" list >&2

        return "$status"
    fi

    __select_categories selected_categories "${requested_categories[@]}" || status=$?
    if (( status != 0 )); then
        if (( status == 2 )); then
            bash "$MP_COMMAND/help.sh" list >&2
        fi

        return "$status"
    fi

    case "${args[0]}" in
        category)
            __print_categories "${selected_categories[@]}"
            ;;
        modules)
            __print_modules "${selected_categories[@]}"
            ;;
    esac
}

main "$@"
