#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_UPDATER/versioning.sh"

readonly __APT_CACHE_MAX_AGE_DAYS=7
readonly __DEFAULT_WORKERS=6
readonly __MAX_WORKERS=9

# Inspection results, filled by __inspect_modules and read by __print_versions.
declare -a __SHOWN_IDS=()
declare -A __VERSION_INSTALLED=()
declare -A __VERSION_LATEST=()
declare -A __VERSION_STATES=()
declare -A __VERSION_NOTES=()
__FAILED=0

# Async work directory and worker PIDs, used by the EXIT, INT, and TERM traps.
__WORK_DIR=""
declare -a __WORKER_PIDS=()

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [HELP]=0
        [ASYNC]=0
        [WORKERS]="$__DEFAULT_WORKERS"
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -h | --help)
                options_ref[HELP]=1
                shift
                ;;
            --async | --batch)
                options_ref[ASYNC]=1
                shift
                if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
                    options_ref[WORKERS]="$1"
                    shift
                fi
                ;;
            --async=* | --batch=*)
                options_ref[ASYNC]=1
                options_ref[WORKERS]="${1#*=}"
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

    if (( options_ref[ASYNC] )) && { [[ ! "${options_ref[WORKERS]}" =~ ^[0-9]+$ ]] ||
        (( 10#${options_ref[WORKERS]} < 1 || 10#${options_ref[WORKERS]} > __MAX_WORKERS )); }; then
        log_error "Worker count must be between 1 and %d: %s" "$__MAX_WORKERS" "${options_ref[WORKERS]}"

        return 2
    fi

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
# __inspect_module <canonical_id> <versions_name>
#
# Detects the installed state and versions of one module and fills the
# associative array <versions_name> with [INSTALLED], [LATEST], [STATE], and
# [NOTE].
#
# Return:
#   1 - Detection or a version query failed; the row is still filled.
#   2 - Module metadata cannot be parsed; the row is not filled.
#
__inspect_module() {
    local canonical_id="$1"
    local versions_name="$2"
    local -n inspect_ref="$versions_name"
    local -A module_metadata=()
    local status=0

    parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata || return 2

    module_installed "$canonical_id" module_metadata >/dev/null || status=$?

    case "$status" in
        0)
            resolve_module_versions "$canonical_id" module_metadata "$versions_name" || return 1
            ;;
        1)
            inspect_ref=([INSTALLED]="-" [LATEST]="-" [STATE]="missing" [NOTE]="not installed")
            ;;
        *)
            inspect_ref=([INSTALLED]="-" [LATEST]="-" [STATE]="error" [NOTE]="detection failed")

            return 1
            ;;
    esac

    return 0
}

__store_versions() {
    local canonical_id="$1"

    __SHOWN_IDS+=("$canonical_id")
    __VERSION_INSTALLED["$canonical_id"]="$2"
    __VERSION_LATEST["$canonical_id"]="$3"
    __VERSION_STATES["$canonical_id"]="$4"
    __VERSION_NOTES["$canonical_id"]="$5"
}

##
# __inspect_modules <canonical_id...>
#
# Inspects modules one at a time and stores the results in the __SHOWN_IDS and
# __VERSION_* globals. Sets __FAILED when detection or a version query fails.
#
# Return:
#   1 when module metadata cannot be parsed.
#
__inspect_modules() {
    local -A versions=()
    local canonical_id
    local status
    local index=0

    for canonical_id in "$@"; do
        ((index += 1))
        __show_status "$canonical_id" "$index" "$#"

        versions=()
        status=0
        __inspect_module "$canonical_id" versions || status=$?

        if (( status > 1 )); then
            __clear_status

            return 1
        fi

        if (( status == 1 )); then
            __FAILED=1
        fi

        __store_versions "$canonical_id" \
            "${versions[INSTALLED]:-}" "${versions[LATEST]:-}" "${versions[STATE]:-unknown}" "${versions[NOTE]:-}"
    done

    __clear_status

    return 0
}

##
# __dequeue <work_dir> <total>
#
# Takes the next queue index under the queue lock.
#
# Output:
#   Prints the zero-based index of the next module.
#
# Return:
#   1 when the queue is empty or the lock cannot be taken.
#
__dequeue() {
    local work_dir="$1"
    local total="$2"
    local index

    {
        flock 9 || return 1
        index="$(<"$work_dir/next")" || return 1
        if (( index >= total )); then
            return 1
        fi

        printf '%d\n' "$(( index + 1 ))" >"$work_dir/next"
    } 9>"$work_dir/queue.lock"

    printf '%d\n' "$index"
}

##
# __draw_worker_line <work_dir> <workers> <worker> [text]
#
# Redraws the status line owned by <worker> inside the block of <workers>
# lines above the cursor, then returns the cursor below the block. An empty
# text clears the line.
#
__draw_worker_line() {
    local work_dir="$1"
    local workers="$2"
    local worker="$3"
    local text="${4:-}"
    local up=$(( workers - worker + 1 ))

    {
        flock 9 || return 0
        printf '\033[%dA\r\033[2K%s\033[%dB\r' "$up" "$text" "$up" >&2
    } 9>"$work_dir/draw.lock"
}

##
# __run_worker <worker> <workers> <work_dir> <draw> <canonical_id...>
#
# Takes modules from the shared queue until it is empty. Each result is written
# to result.<index> as status, INSTALLED, LATEST, STATE, and NOTE separated by
# \x1f; module logs are written to log.<index>.
#
__run_worker() {
    local worker="$1"
    local workers="$2"
    local work_dir="$3"
    local draw="$4"
    shift 4

    local -a queue=("$@")
    local -A versions=()
    local canonical_id
    local index
    local status
    local text

    while index="$(__dequeue "$work_dir" "${#queue[@]}")"; do
        canonical_id="${queue[index]}"

        if (( draw )); then
            printf -v text '%b[INFO]%b [worker-%d] [%d/%d] inspecting module %s' \
                "$COLOR_BLUE" "$COLOR_RESET" "$worker" "$(( index + 1 ))" "${#queue[@]}" "$canonical_id"
            __draw_worker_line "$work_dir" "$workers" "$worker" "$text"
        fi

        versions=()
        status=0
        __inspect_module "$canonical_id" versions 2>"$work_dir/log.$index" || status=$?

        printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\n' "$status" \
            "${versions[INSTALLED]:-}" "${versions[LATEST]:-}" "${versions[STATE]:-unknown}" "${versions[NOTE]:-}" \
            >"$work_dir/result.$index.tmp" &&
            mv "$work_dir/result.$index.tmp" "$work_dir/result.$index"
    done

    if (( draw )); then
        __draw_worker_line "$work_dir" "$workers" "$worker"
    fi
}

# Background jobs start with SIGINT ignored, so the main process stops them.
__stop_workers() {
    if (( ${#__WORKER_PIDS[@]} > 0 )); then
        kill -- "${__WORKER_PIDS[@]}" 2>/dev/null || true
    fi
}

##
# __inspect_modules_async <workers> <canonical_id...>
#
# Inspects modules with a pool of background workers sharing one queue, then
# loads the results into the __SHOWN_IDS and __VERSION_* globals in queue
# order. Worker logs are replayed after the pool finishes. Sets __FAILED when
# detection, a version query, or a worker fails.
#
# Return:
#   1 when the work directory cannot be created or module metadata cannot be
#   parsed.
#
__inspect_modules_async() {
    local workers="$1"
    shift

    local draw=0
    local worker
    local pid
    local index
    local status
    local installed
    local latest
    local state
    local note

    if (( $# == 0 )); then
        return 0
    fi

    if (( workers > $# )); then
        workers=$#
    fi

    if ! __WORK_DIR="$(mktemp -d)"; then
        log_error "Failed to create a work directory for async inspection"

        return 1
    fi

    trap '[[ -z "$__WORK_DIR" ]] || rm -rf -- "$__WORK_DIR"' EXIT
    trap '__stop_workers; exit 130' INT
    trap '__stop_workers; exit 143' TERM
    printf '0\n' >"$__WORK_DIR/next"

    if [[ -t 2 ]]; then
        draw=1
        printf '%*s' "$workers" "" | tr ' ' '\n' >&2
    fi

    for (( worker = 1; worker <= workers; worker += 1 )); do
        (
            trap - EXIT INT TERM
            __run_worker "$worker" "$workers" "$__WORK_DIR" "$draw" "$@"
        ) &
        __WORKER_PIDS+=("$!")
    done

    for pid in "${__WORKER_PIDS[@]}"; do
        wait "$pid" || __FAILED=1
    done

    if (( draw )); then
        printf '\033[%dA\r\033[J' "$workers" >&2
    fi

    for (( index = 0; index < $#; index += 1 )); do
        if [[ -s "$__WORK_DIR/log.$index" ]]; then
            cat "$__WORK_DIR/log.$index" >&2
        fi

        if [[ ! -f "$__WORK_DIR/result.$index" ]]; then
            __store_versions "${*:index + 1:1}" "-" "-" "error" "inspection failed"
            __FAILED=1

            continue
        fi

        IFS=$'\x1f' read -r status installed latest state note <"$__WORK_DIR/result.$index"

        if (( status > 1 )); then
            return 1
        fi

        if (( status == 1 )); then
            __FAILED=1
        fi

        __store_versions "${*:index + 1:1}" "$installed" "$latest" "$state" "$note"
    done

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
        [untracked]=0
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

    if (( counts[untracked] > 0 )); then
        printf ', %d not tracked' "${counts[untracked]}"
    fi

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

    if (( options[ASYNC] )); then
        __inspect_modules_async "$(( 10#${options[WORKERS]} ))" "${canonical_ids[@]}" || return $?
    else
        __inspect_modules "${canonical_ids[@]}" || return $?
    fi
    __print_versions "$explicit"

    return "$__FAILED"
}

main "$@"
