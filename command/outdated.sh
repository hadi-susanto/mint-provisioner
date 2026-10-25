#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_UPDATER/versioning.sh"

readonly __APT_CACHE_MAX_AGE_DAYS=7

# Inspection results, filled by __inspect_modules and read by __print_versions.
declare -a __SHOWN_IDS=()
declare -A __VERSION_INSTALLED=()
declare -A __VERSION_LATEST=()
declare -A __VERSION_STATES=()
declare -A __VERSION_NOTES=()
__FAILED=0

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
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
                log_error "Unsupported outdated option: %s" "$1"

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

__show_status() {
    local canonical_id="$1"
    local index="$2"
    local total="$3"

    if [[ -t 2 ]]; then
        printf '\033[2K\r%b[INFO]%b Inspecting %s (%d/%d)' \
            "$COLOR_BLUE" "$COLOR_RESET" "$canonical_id" "$index" "$total" >&2
    fi
}

__clear_status() {
    if [[ -t 2 ]]; then
        printf '\033[2K\r' >&2
    fi
}

##
# __inspect_modules <canonical_id...>
#
# Detects the installed state and versions of each module and stores the
# results in the __SHOWN_IDS and __VERSION_* globals. Sets __FAILED when
# detection or a version query fails.
#
# Return:
#   Non-zero when module metadata cannot be parsed.
#
__inspect_modules() {
    local -A metadata=()
    local -A versions=()
    local canonical_id
    local status
    local index=0

    for canonical_id in "$@"; do
        ((index += 1))
        __show_status "$canonical_id" "$index" "$#"

        if parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
            :
        else
            status=$?
            __clear_status

            return "$status"
        fi

        __SHOWN_IDS+=("$canonical_id")

        if module_installed "$canonical_id" metadata >/dev/null; then
            status=0
        else
            status=$?
        fi

        case "$status" in
            0)
                resolve_module_versions "$canonical_id" metadata versions || __FAILED=1
                ;;
            1)
                versions=([INSTALLED]="-" [LATEST]="-" [STATE]="missing" [NOTE]="not installed")
                ;;
            *)
                versions=([INSTALLED]="-" [LATEST]="-" [STATE]="error" [NOTE]="detection failed")
                __FAILED=1
                ;;
        esac

        __VERSION_INSTALLED["$canonical_id"]="${versions[INSTALLED]}"
        __VERSION_LATEST["$canonical_id"]="${versions[LATEST]}"
        __VERSION_STATES["$canonical_id"]="${versions[STATE]}"
        __VERSION_NOTES["$canonical_id"]="${versions[NOTE]}"
    done

    __clear_status

    return 0
}

__uses_apt_versions() {
    local -A metadata=()
    local canonical_id

    for canonical_id in "$@"; do
        parse_module_metadata "$MP_MODULES/$canonical_id" metadata || return $?
        if [[ "${metadata[UPDATE_MODE]:-}" == "apt" ]]; then
            return 0
        fi
    done

    return 1
}

##
# __offer_apt_refresh
#
# Offers to run apt-get update when the APT cache is older than
# __APT_CACHE_MAX_AGE_DAYS. Without a terminal, only warns. Failures leave the
# existing cache in use.
#
__offer_apt_refresh() {
    local DISABLE_WHIPTAIL=true
    local age
    local status=0

    if ! age="$(apt_cache_age_days)"; then
        log_warn "Unable to determine the APT cache age; versions may be outdated"

        return 0
    fi

    if (( age <= __APT_CACHE_MAX_AGE_DAYS )); then
        return 0
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        log_warn "APT cache is %d days old; run 'sudo apt-get update' for current versions" "$age"

        return 0
    fi

    if ! source "$LIB_INSTALLER/prompt.sh"; then
        log_warn "Continuing with the existing APT cache"

        return 0
    fi

    ask_confirm "APT cache is $age days old. Run 'sudo apt-get update' now?" || status=$?
    if (( status == 0 )); then
        refresh_apt_cache || log_warn "Continuing with the existing APT cache"
    elif (( status != 1 )); then
        log_warn "Continuing with the existing APT cache"
    fi

    return 0
}

##
# __print_versions <explicit>
#
# Prints the version table and summary from the inspection globals.
# Not-installed modules are printed only when explicitly selected.
#
__print_versions() {
    local explicit="$1"
    local -A counts=(
        [outdated]=0
        [current]=0
        [unknown]=0
        [unsupported]=0
        [missing]=0
        [error]=0
    )
    local -a ids=()
    local canonical_id
    local state
    local installed
    local latest
    local color
    local color_reset
    local module_width=6
    local installed_width=9
    local latest_width=6

    for canonical_id in "${__SHOWN_IDS[@]}"; do
        state="${__VERSION_STATES[$canonical_id]}"
        if [[ "$state" == "missing" ]] && (( ! explicit )); then
            continue
        fi

        ids+=("$canonical_id")
        counts["$state"]=$(( counts["$state"] + 1 ))

        installed="${__VERSION_INSTALLED[$canonical_id]:-[unknown]}"
        latest="${__VERSION_LATEST[$canonical_id]:-[unknown]}"

        if (( ${#canonical_id} > module_width )); then
            module_width=${#canonical_id}
        fi

        if (( ${#installed} > installed_width )); then
            installed_width=${#installed}
        fi

        if (( ${#latest} > latest_width )); then
            latest_width=${#latest}
        fi
    done

    if (( ${#ids[@]} == 0 )); then
        printf 'No installed modules.\n'

        return 0
    fi

    printf '%-*s  %-*s  %-*s  %s\n' \
        "$module_width" "MODULE" "$installed_width" "INSTALLED" \
        "$latest_width" "LATEST" "NOTES"

    for canonical_id in "${ids[@]}"; do
        color=""
        color_reset="$COLOR_RESET"

        case "${__VERSION_STATES[$canonical_id]}" in
            outdated)
                color="$COLOR_BLUE"
                ;;
            unknown | unsupported | error)
                color="$COLOR_YELLOW"
                ;;
            missing)
                color="$COLOR_GRAY"
                ;;
            *)
                color_reset=""
                ;;
        esac

        printf '%s%-*s  %-*s  %-*s  %s%s\n' "$color" \
            "$module_width" "$canonical_id" \
            "$installed_width" "${__VERSION_INSTALLED[$canonical_id]:-[unknown]}" \
            "$latest_width" "${__VERSION_LATEST[$canonical_id]:-[unknown]}" \
            "${__VERSION_NOTES[$canonical_id]}" "$color_reset"
    done

    printf '\n%d update available, %d up to date, %d unknown' \
        "${counts[outdated]}" "${counts[current]}" \
        "$(( counts[unknown] + counts[unsupported] ))"

    if (( counts[missing] > 0 )); then
        printf ', %d not installed' "${counts[missing]}"
    fi

    if (( counts[error] > 0 )); then
        printf ', %d failed detection' "${counts[error]}"
    fi

    printf '\n'
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local explicit=0
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" outdated >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" outdated

        return 0
    fi

    if (( EUID == 0 )); then
        log_error "Do not run 'mp outdated' with sudo or as root"
        log_error "Installed-state detection would inspect root's \$HOME instead of yours"

        return 2
    fi

    if (( ${#args[@]} > 0 )); then
        explicit=1

        if ! resolve_module_selectors canonical_ids "${args[@]}"; then
            log_error "Version check aborted because one or more modules could not be resolved"

            return 2
        fi
    else
        list_modules canonical_ids || return $?
    fi

    if __uses_apt_versions "${canonical_ids[@]}"; then
        __offer_apt_refresh
    fi

    __inspect_modules "${canonical_ids[@]}" || return $?
    __print_versions "$explicit"

    return "$__FAILED"
}

main "$@"
