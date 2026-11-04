#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_UPDATER/upgrader.sh"
source "$LIB_UPDATER/versioning.sh"

# Phase scripts in lifecycle order, shown when the module ships them.
readonly -a __INFO_INSTALL_PHASES=(installed interactive non-interactive pre-install install post-install cleanup)
readonly -a __INFO_UPGRADE_PHASES=(latest pre-upgrade upgrade)
# Registry keys shown as module details; SCHEMA_VERSION is internal.
readonly -a __INFO_REGISTRY_KEYS=(INSTALL_PATH VERSION DATA_PATH)
readonly -A __INFO_REGISTRY_LABELS=(
    [INSTALL_PATH]="Install path"
    [VERSION]="Version"
    [DATA_PATH]="Data path"
)

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [LATEST]=0
        [INSTALLED]=0
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            --latest)
                options_ref[LATEST]=1
                shift
                ;;
            --installed)
                options_ref[INSTALLED]=1
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
                log_error "Unsupported info option: %s" "$1"

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

    if (( options_ref[INSTALLED] && ${#args_ref[@]} > 0 )); then
        log_error "The --installed option cannot be combined with module names"

        return 2
    fi

    if (( ! options_ref[INSTALLED] && ${#args_ref[@]} == 0 )); then
        log_error "Specify at least one module or use --installed"

        return 2
    fi
}

__print_field() {
    printf '  %b%-15s%b %s\n' "$COLOR_CYAN" "$1" "$COLOR_RESET" "$2"
}

##
# __existing_phases <canonical_id> <phase...>
#
# Prints the given phases that the module ships as scripts, separated by spaces.
#
__existing_phases() {
    local canonical_id="$1"
    shift

    local -a found=()
    local phase

    for phase in "$@"; do
        if [[ -f "$MP_MODULES/$canonical_id/$phase.sh" ]]; then
            found+=("$phase")
        fi
    done

    printf '%s\n' "${found[*]:--}"
}

__print_update_mode() {
    local metadata_name="$1"
    local -n mode_metadata_ref="$metadata_name"
    local mode="${mode_metadata_ref[UPDATE_MODE]:-none}"

    case "$mode" in
        apt)
            __print_field "Update mode" "apt (packages: ${mode_metadata_ref[UPDATE_PACKAGE]//,/, })"
            ;;
        github)
            __print_field "Update mode" "github (repository: ${mode_metadata_ref[UPDATE_REPOSITORY]})"
            ;;
        *)
            __print_field "Update mode" "$mode"
            ;;
    esac
}

##
# __print_state <canonical_id> <installed_status>
#
# Prints the installed state and the registry details of an installed module.
#
# Return:
#   1 when the registry is malformed or unreadable.
#
__print_state() {
    local canonical_id="$1"
    local installed_status="$2"
    local registry_status=0
    local key

    case "$installed_status" in
        0)
            __print_field "Status" "$(printf '%b✓ installed%b' "$COLOR_GREEN" "$COLOR_RESET")"
            ;;
        1)
            __print_field "Status" "$(printf '%b✗ not installed%b' "$COLOR_RED" "$COLOR_RESET")"
            ;;
        *)
            __print_field "Status" "$(printf '%b⚠ detection failed%b' "$COLOR_YELLOW" "$COLOR_RESET")"
            ;;
    esac

    load_registry "$canonical_id" silent 2>/dev/null || registry_status=$?
    case "$registry_status" in
        0)
            for key in "${__INFO_REGISTRY_KEYS[@]}"; do
                if has_registry "$key"; then
                    __print_field "${__INFO_REGISTRY_LABELS[$key]}" "$(get_registry "$key")"
                fi
            done
            ;;
        1)
            ;;
        *)
            __print_field "Registry" "$(printf '%bmalformed or unreadable; run mp doctor%b' \
                "$COLOR_RED" "$COLOR_RESET")"

            return 1
            ;;
    esac
}

##
# __print_latest <canonical_id> <metadata_name>
#
# Prints the installed and latest versions of an installed module.
#
# Return:
#   1 when a version query failed.
#
__print_latest() {
    local canonical_id="$1"
    local metadata_name="$2"
    local -A info_versions=()
    local status=0

    resolve_module_versions "$canonical_id" "$metadata_name" info_versions || status=$?

    __print_field "Installed" "${info_versions[INSTALLED]:-[unknown]}"
    __print_field "Latest" "${info_versions[LATEST]:-[unknown]}"
    __print_field "Version state" \
        "${info_versions[STATE]:-unknown}${info_versions[NOTE]:+ (${info_versions[NOTE]})}"

    return "$status"
}

__print_links() {
    local canonical_id="$1"
    local metadata_name="$2"
    local -n links_metadata_ref="$metadata_name"
    local category="${canonical_id%%/*}"
    local docs="modules/${category^^}.md"

    if [[ -f "$MP_ROOT/$docs" ]]; then
        __print_field "Docs" "$MP_ROOT/$docs"
    fi

    if [[ -n "${links_metadata_ref[UPDATE_REPOSITORY]:-}" ]]; then
        __print_field "Releases" "https://github.com/${links_metadata_ref[UPDATE_REPOSITORY]}/releases"
    fi
}

##
# __print_module <canonical_id> <latest> <installed_only> <separator>
#
# Prints the details page of one module, preceded by the separator.
#
# Return:
#   1 when detection, the registry, or a version query failed.
#   3 when installed_only is 1 and the module is not installed; nothing is printed.
#
__print_module() {
    local canonical_id="$1"
    local latest="$2"
    local installed_only="$3"
    local separator="$4"
    local -A info_metadata=()
    local -a aliases=()
    local installed_status=0
    local status=0
    local upgradable="no"
    local removable="no"

    parse_module_metadata "$MP_MODULES/$canonical_id" info_metadata || return 1
    resolve_module_aliases "$canonical_id" aliases || return 1
    module_installed "$canonical_id" info_metadata >/dev/null || installed_status=$?

    if (( installed_only && installed_status == 1 )); then
        return 3
    fi

    if module_upgradable "$canonical_id" info_metadata; then
        upgradable="yes"
    fi

    if [[ -f "$MP_MODULES/$canonical_id/remove.sh" ]]; then
        removable="yes"
    fi

    printf '%b%b%s%b %b[id: %s]%b\n' \
        "$separator" "$COLOR_BLUE" "${info_metadata[NAME]}" "$COLOR_RESET" \
        "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
    printf '%s\n' '-----------------------------------'
    __print_field "Description" "${info_metadata[DESCRIPTION]}"
    __print_field "Aliases" "${aliases[*]:--}"
    __print_field "Source" "${info_metadata[SOURCE]}"
    __print_field "CLI" "${info_metadata[CLI]:--}"
    __print_update_mode info_metadata

    __print_state "$canonical_id" "$installed_status" || status=1
    if (( installed_status > 1 )); then
        status=1
    fi

    if (( latest )); then
        if (( installed_status == 0 )); then
            __print_latest "$canonical_id" info_metadata || status=1
        else
            __print_field "Latest" "- (not installed)"
        fi
    fi

    __print_field "Install phases" "$(__existing_phases "$canonical_id" "${__INFO_INSTALL_PHASES[@]}")"
    __print_field "Upgrade phases" "$(__existing_phases "$canonical_id" "${__INFO_UPGRADE_PHASES[@]}")"
    __print_field "Upgradable" "$upgradable"
    __print_field "Removable" "$removable"
    __print_links "$canonical_id" info_metadata

    return "$status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local canonical_id
    local status=0
    local module_status
    local shown=0
    local separator=""

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" info >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" info

        return 0
    fi

    __validate_options options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" info >&2

        return "$status"
    fi

    if (( options[INSTALLED] )); then
        list_modules canonical_ids || return $?
    elif ! resolve_module_selectors canonical_ids "${args[@]}"; then
        log_error "Use a canonical <category>/<module> ID; see mp list modules"

        return 2
    fi

    for canonical_id in "${canonical_ids[@]}"; do
        module_status=0
        __print_module "$canonical_id" "${options[LATEST]}" "${options[INSTALLED]}" "$separator" ||
            module_status=$?

        case "$module_status" in
            3)
                continue
                ;;
            0)
                ;;
            *)
                status=1
                ;;
        esac

        separator='\n'
        (( shown += 1 ))
    done

    if (( options[INSTALLED] && shown == 0 )); then
        printf 'No installed modules.\n'
    fi

    return "$status"
}

main "$@"
