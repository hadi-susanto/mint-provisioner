#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"

# Global Variable to help store category metadata
declare -A __CATEGORY_NAMES=()
declare -A __CATEGORY_DESCRIPTIONS=()
# Global Variable to help store module metadata
declare -A __MODULE_NAMES=()
declare -A __MODULE_DESCRIPTIONS=()
declare -A __MODULE_SOURCES=()
declare -A __MODULE_STATUSES=()

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

    case "${options_ref[STATUS]}" in
        all | installed | not-installed)
            ;;
        *)
            log_error \
                "Unsupported list status '%s'; supported statuses: all, installed, not-installed" \
                "${options_ref[STATUS]}"

            return 2
            ;;
    esac

    if [[ "${args_ref[0]}" == "category" ]] &&
        [[ "${options_ref[STATUS]}" != "all" ]]; then
        log_error "Status filters apply only to module listings"

        return 2
    fi

    return 0
}

__resolve_categories() {
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
    local -A metadata=()
    local category_id

    __CATEGORY_NAMES=()
    __CATEGORY_DESCRIPTIONS=()

    for category_id in "$@"; do
        parse_category_metadata "$MP_MODULES/$category_id" metadata || return $?

        __CATEGORY_NAMES["$category_id"]="${metadata[NAME]}"
        __CATEGORY_DESCRIPTIONS["$category_id"]="${metadata[DESCRIPTION]}"
    done

    return 0
}

__print_categories() {
    local category_id
    local index=1

    # Preload metadata so invalid entries fail before output begins.
    __load_category_metadata "$@" || return $?

    printf 'Mint Provisioner Supported Categories\n'
    printf '%s\n' '====================================='

    if (( $# == 0 )); then
        printf 'No supported categories.\n'

        return 0
    fi

    for category_id in "$@"; do
        printf '%2d. %b%s%b %b[id: %s]%b\n' \
            "$index" \
            "$COLOR_BLUE" "${__CATEGORY_NAMES[$category_id]}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$category_id" "$COLOR_RESET"
        printf '    %s\n' "${__CATEGORY_DESCRIPTIONS[$category_id]}"

        ((index += 1))
    done

    return 0
}

__inspect_modules() {
    local -A metadata=()
    local canonical_id
    local status

    __MODULE_NAMES=()
    __MODULE_DESCRIPTIONS=()
    __MODULE_SOURCES=()
    __MODULE_STATUSES=()

    for canonical_id in "$@"; do
        parse_module_metadata "$MP_MODULES/$canonical_id" metadata || return $?

        __MODULE_NAMES["$canonical_id"]="${metadata[NAME]}"
        __MODULE_DESCRIPTIONS["$canonical_id"]="${metadata[DESCRIPTION]}"
        __MODULE_SOURCES["$canonical_id"]="${metadata[SOURCE]}"

        if module_installed "$canonical_id" metadata >/dev/null; then
            status=0
        else
            status=$?
        fi

        __MODULE_STATUSES["$canonical_id"]="$status"
    done

    return 0
}

__module_matches_status() {
    local status_filter="$1"
    local module_status="$2"

    case "$status_filter" in
        all)
            return 0
            ;;
        installed)
            (( module_status == 0 ))
            ;;
        not-installed)
            (( module_status == 1 ))
            ;;
    esac
}

__print_module_aliases() {
    local canonical_id="$1"
    local -a aliases=()
    local alias

    resolve_module_aliases "$canonical_id" aliases
    for alias in "${aliases[@]}"; do
        printf ' %b[alias: %s]%b' "$COLOR_CYAN" "$alias" "$COLOR_RESET"
    done
}

__print_module_features() {
    local canonical_id="$1"
    local script="$MP_MODULES/$canonical_id/interactive.sh"
    if [[ -f "$script" && ! -L "$script" ]]; then
        printf ' %b[interactive]%b' "$COLOR_CYAN" "$COLOR_RESET"
    fi

    script="$MP_MODULES/$canonical_id/post_install.sh"
    if [[ -f "$script" && ! -L "$script" ]]; then
        printf ' %b[post-install]%b' "$COLOR_CYAN" "$COLOR_RESET"
    fi
}

__print_installation_status() {
    local module_status="$1"
    local color
    local icon

    case "$module_status" in
        0)
            color="$COLOR_GREEN"
            icon="✓"
            ;;
        1)
            color="$COLOR_RED"
            icon="✗"
            ;;
        *)
            color="$COLOR_YELLOW"
            icon="⚠"
            ;;
    esac

    printf ' %b[%s]%b' "$color" "$icon" "$COLOR_RESET"
}

__print_module_category_header() {
    local category_id="$1"

    printf '\n%b%s%b %b[id: %s]%b\n' \
        "$COLOR_GREEN" "${__CATEGORY_NAMES[$category_id]}" "$COLOR_RESET" \
        "$COLOR_YELLOW" "$category_id" "$COLOR_RESET"
    printf '%s\n' '-----------------------------------'
}

__warn_unknown_modules() {
    local category_id="$1"
    local unknown_count="$2"
    local module_label="modules"

    if (( unknown_count == 1 )); then
        module_label="module"
    fi

    log_warn \
        "Installation state is unknown for %d %s in category '%s'; filtered results may be incomplete. Use 'mp list modules -c %s -s all' to inspect them." \
        "$unknown_count" "$module_label" "$category_id" "$category_id"
}

__print_modules() {
    local status_filter="$1"
    shift

    local -a modules=()
    local canonical_id
    local category_id
    local category
    local module_status
    local category_has_modules
    local matched_count
    local unknown_count
    local filtered_count
    local detection_failed=0
    local index

    list_modules modules "$@" || return $?
    __load_category_metadata "$@" || return $?
    __inspect_modules "${modules[@]}" || return $?

    printf 'Mint Provisioner Supported Modules\n'
    printf '==================================='

    if (( ${#modules[@]} == 0 )); then
        printf '\nNo supported modules.\n'

        return 0
    fi

    for category in "$@"; do
        __print_module_category_header "$category"

        category_has_modules=0
        matched_count=0
        unknown_count=0
        filtered_count=0
        index=1

        # We can do single loop, but for simplicity's sake we do double loop
        for canonical_id in "${modules[@]}"; do
            category_id="${canonical_id%%/*}"
            if [[ "$category_id" != "$category" ]]; then
                continue
            fi

            category_has_modules=1
            module_status="${__MODULE_STATUSES[$canonical_id]}"

            if (( module_status > 1 )); then
                ((unknown_count += 1))
                detection_failed=1
            fi

            if ! __module_matches_status "$status_filter" "$module_status"; then
                ((filtered_count += 1))

                continue
            fi

            printf '%2s.' "$index"
            __print_installation_status "$module_status"
            printf ' %b%s%b' "$COLOR_BLUE" "${__MODULE_NAMES[$canonical_id]}" "$COLOR_RESET"
            printf ' %b[id: %s]%b' "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
            __print_module_aliases "$canonical_id"
            __print_module_features "$canonical_id"
            printf ' %b[src: %s]%b' "$COLOR_GRAY" "${__MODULE_SOURCES[$canonical_id]}" "$COLOR_RESET"
            printf '\n'
            printf '    %s\n' "${__MODULE_DESCRIPTIONS[$canonical_id]}"

            ((index += 1))
            ((matched_count += 1))
        done

        if (( ! category_has_modules )); then
            printf '  %bNo supported modules.%b\n' "$COLOR_GRAY" "$COLOR_RESET"
        elif (( matched_count == 0 )); then
            printf "  %bNo modules with confirmed status '%s'.%b\n" \
                "$COLOR_GRAY" "$status_filter" "$COLOR_RESET"
        elif (( filtered_count > 0)); then
            printf "  %bShowing %d matching module(s) of %d%b\n" \
                "$COLOR_GRAY" "$matched_count" \
                "$((matched_count + filtered_count))" "$COLOR_RESET"
        fi

        if [[ "$status_filter" != "all" ]] && (( unknown_count > 0 )); then
            __warn_unknown_modules "$category" "$unknown_count"
        fi
    done

    printf '\nLegend:\n'
    printf '  %b[✓]%b: Module installed\n' "$COLOR_GREEN" "$COLOR_RESET"
    printf '  %b[✗]%b: Module not-installed, use id or alias(es) to install\n' "$COLOR_RED" "$COLOR_RESET"
    printf '  %b[⚠]%b: Detection failed\n' "$COLOR_YELLOW" "$COLOR_RESET"

    return "$detection_failed"
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

    __resolve_categories selected_categories "${requested_categories[@]}" || status=$?
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
            __print_modules "${options[STATUS]}" "${selected_categories[@]}"
            ;;
    esac
}

main "$@"
