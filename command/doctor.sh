#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_UPDATER/apt-versioning.sh"

# Keep in sync with __DEPENDENCIES in bootstrap.sh (command -> package).
readonly -A __REQUIRED_TOOLS=(
    [git]="git"
    [jq]="jq"
    [aria2c]="aria2"
    [curl]="curl"
    [sudo]="sudo"
)
# Keep in sync with the links bootstrap.sh creates.
readonly __COMMAND_LINK="/usr/local/bin/mp"
readonly __COMPLETION_LINK="$HOME/.local/share/bash-completion/completions/mp"
readonly __DESKTOP_DIR="/usr/share/applications"
readonly __GITHUB_RATE_LIMIT_URL="https://api.github.com/rate_limit"
readonly __GITHUB_MIN_REMAINING=10

# Per-run check counters, filled by __report.
declare -A __DOCTOR_COUNTS=(
    [OK]=0
    [WARN]=0
    [FAIL]=0
)

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [OFFLINE]=0
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            --offline)
                options_ref[OFFLINE]=1
                shift
                ;;
            -h | --help)
                options_ref[HELP]=1
                shift
                ;;
            -*)
                log_error "Unsupported doctor option: %s" "$1"

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

    if (( ${#args_ref[@]} > 0 )); then
        log_error "The doctor command does not accept arguments: %s" "${args_ref[*]}"

        return 2
    fi
}

##
# __report <level> <message> [hint]
#
# Prints one check result and counts it. Level is OK, WARN, or FAIL.
#
__report() {
    local level="$1"
    local message="$2"
    local hint="${3:-}"
    local color

    case "$level" in
        OK)
            color="$COLOR_GREEN"
            ;;
        WARN)
            color="$COLOR_YELLOW"
            ;;
        FAIL)
            color="$COLOR_RED"
            ;;
    esac

    (( __DOCTOR_COUNTS[$level] += 1 ))
    printf '  %b%-6s%b %s\n' "$color" "[$level]" "$COLOR_RESET" "$message"

    if [[ -n "$hint" ]]; then
        printf '         %b→ %s%b\n' "$COLOR_GRAY" "$hint" "$COLOR_RESET"
    fi
}

__print_section() {
    printf '\n%b%s%b\n' "$COLOR_BLUE" "$1" "$COLOR_RESET"
}

##
# __check_link <link> <expected_target> <label> <hint>
#
# Reports whether a symbolic link resolves to the expected file of this clone.
#
__check_link() {
    local link="$1"
    local expected="$2"
    local label="$3"
    local hint="$4"
    local resolved

    if [[ ! -e "$link" ]]; then
        __report WARN "$label is missing: $link" "$hint"

        return 0
    fi

    resolved="$(readlink -f -- "$link")"
    if [[ "$resolved" != "$(readlink -f -- "$expected")" ]]; then
        __report WARN "$label points to $resolved, not this clone" "$hint"

        return 0
    fi

    __report OK "$label: $link"
}

__check_environment() {
    __print_section "Environment"

    if (( EUID == 0 )); then
        __report FAIL "Running as root" "Run mp as your normal user; modules invoke sudo themselves"
    else
        __report OK "Running as ${USER:-$(id -un)} (not root)"
    fi

    __check_link "$__COMMAND_LINK" "$MP_ROOT/mp" "mp command link" \
        "Re-run bootstrap.sh from the folder that holds this clone"
    __check_link "$__COMPLETION_LINK" "$MP_ROOT/completion/mp.bash" "Bash completion link" \
        "Re-run bootstrap.sh or see README.md (Shell Completion)"

    if [[ -d "$INSTALL_DIR" && -w "$INSTALL_DIR" ]]; then
        __report OK "INSTALL_DIR is writable: $INSTALL_DIR"
    else
        __report FAIL "INSTALL_DIR is not a writable directory: $INSTALL_DIR" \
            "Create it or set INSTALL_DIR to an absolute, writable directory"
    fi
}

__check_tools() {
    local tool

    __print_section "Tools"

    for tool in git jq aria2c curl sudo; do
        if command -v "$tool" >/dev/null 2>&1; then
            __report OK "$tool found"
        else
            __report FAIL "$tool is missing" "sudo apt install ${__REQUIRED_TOOLS[$tool]}"
        fi
    done

    if [[ "${DISABLE_WHIPTAIL:-false}" == "true" ]]; then
        __report OK "whiptail disabled (DISABLE_WHIPTAIL=true); plain-text prompts are used"
    elif command -v whiptail >/dev/null 2>&1; then
        __report OK "whiptail found"
    else
        __report WARN "whiptail is missing; plain-text prompts are used" "sudo apt install whiptail"
    fi
}

__os_pretty_name() {
    local line

    while IFS= read -r line; do
        if [[ "$line" == PRETTY_NAME=* ]]; then
            line="${line#PRETTY_NAME=}"
            line="${line#\"}"
            printf '%s\n' "${line%\"}"

            return 0
        fi
    done </etc/os-release

    printf 'Unknown distribution\n'
}

__check_distro() {
    local version
    local codename

    __print_section "Distribution"

    if ! version="$(get_ubuntu_version 2>/dev/null)" ||
        ! codename="$(get_ubuntu_codename 2>/dev/null)"; then
        __report FAIL "Not recognized as a supported Ubuntu-based distribution" \
            "Mint Provisioner supports Linux Mint and Ubuntu; see /etc/os-release"

        return 0
    fi

    __report OK "$(__os_pretty_name 2>/dev/null) (Ubuntu $version $codename)"
}

__check_apt() {
    local age

    __print_section "APT"

    if ! age="$(apt_cache_age_days)"; then
        __report WARN "Unable to determine the APT cache age" "sudo apt-get update"

        return 0
    fi

    if (( age > APT_CACHE_MAX_AGE_DAYS )); then
        __report WARN "APT cache is $age day(s) old" "sudo apt-get update"

        return 0
    fi

    __report OK "APT cache is $age day(s) old"
}

__check_github_rate_limit() {
    local -a curl_args=(-sS --max-time 10 -w '\n%{http_code}')
    local response
    local http_code
    local body
    local remaining
    local limit
    local reset

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    response="$(curl "${curl_args[@]}" "$__GITHUB_RATE_LIMIT_URL" 2>/dev/null)" || true
    http_code="${response##*$'\n'}"
    body="${response%$'\n'*}"

    if [[ "$http_code" == "401" && -n "${GITHUB_TOKEN:-}" ]]; then
        __report FAIL "GitHub rejected GITHUB_TOKEN (HTTP 401)" \
            "Create a new token or unset GITHUB_TOKEN; see FAQ.md"

        return 0
    fi

    if [[ "$http_code" != "200" ]] ||
        ! read -r remaining limit reset < <(
            jq -r '.resources.core | "\(.remaining) \(.limit) \(.reset)"' <<<"$body" 2>/dev/null
        ) || [[ ! "$remaining" =~ ^[0-9]+$ ]]; then
        __report WARN "Unable to query the GitHub rate limit (HTTP ${http_code:-000})" \
            "Check the network connection, or use --offline"

        return 0
    fi

    if (( remaining < __GITHUB_MIN_REMAINING )); then
        __report WARN "GitHub API calls remaining: $remaining/$limit" \
            "Resets at $(date -d "@$reset" '+%H:%M'); set GITHUB_TOKEN to raise the limit"

        return 0
    fi

    __report OK "GitHub API calls remaining: $remaining/$limit"
}

__check_github() {
    local offline="$1"

    __print_section "GitHub"

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        __report OK "GITHUB_TOKEN is set"
    else
        __report WARN "GITHUB_TOKEN is not set; GitHub API calls are limited to 60 per hour" \
            "See FAQ.md for creating a token"
    fi

    if (( offline )); then
        return 0
    fi

    __check_github_rate_limit
}

##
# __check_registry_entry <canonical_id>
#
# Reports problems of one registry entry.
#
# Return:
#   1 when a problem was reported.
#
__check_registry_entry() {
    local canonical_id="$1"
    local -A module_metadata=()
    local install_path
    local status=0

    if [[ ! -f "$MP_MODULES/$canonical_id/metadata.conf" ]]; then
        __report WARN "$canonical_id: registry for a module that no longer exists" \
            "Delete $canonical_id.registry under ~/.local/state/mint-provisioner/registry"

        return 1
    fi

    if ! load_registry "$canonical_id" silent 2>/dev/null; then
        __report FAIL "$canonical_id: registry is malformed or unreadable" \
            "Fix or delete $canonical_id.registry under ~/.local/state/mint-provisioner/registry"

        return 1
    fi

    if has_registry INSTALL_PATH; then
        install_path="$(get_registry INSTALL_PATH)"
        if [[ -n "$install_path" && ! -e "$install_path" ]]; then
            __report WARN "$canonical_id: INSTALL_PATH no longer exists: $install_path" \
                "Removed outside mp; run: mp remove -f $canonical_id"
            status=1
        fi
    fi

    parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata 2>/dev/null || return "$status"

    case "${module_metadata[UPDATE_MODE]:-}" in
        github | external)
            if ! has_registry VERSION; then
                __report WARN "$canonical_id: no VERSION recorded; always reported as outdated" \
                    "Run: mp upgrade $canonical_id"
                status=1
            fi
            ;;
    esac

    return "$status"
}

__check_registry() {
    local -a registry_ids=()
    local canonical_id
    local consistent=0

    __print_section "Registry"

    list_registry_ids registry_ids

    for canonical_id in "${registry_ids[@]}"; do
        if __check_registry_entry "$canonical_id"; then
            (( consistent += 1 ))
        fi
    done

    if (( consistent > 0 )); then
        __report OK "$consistent of ${#registry_ids[@]} registry entries are consistent"
    elif (( ${#registry_ids[@]} == 0 )); then
        __report OK "No registry entries"
    fi
}

__check_state_files() {
    local -a state_ids=()

    list_state_ids state_ids

    if (( ${#state_ids[@]} == 0 )); then
        __report OK "No leftover temporary state"

        return 0
    fi

    __report WARN "Leftover temporary state from interrupted runs: ${state_ids[*]}" \
        "Cleaned on the next install of each module"
}

__check_broken_symlinks() {
    local link
    local target
    local -a broken=()

    for link in /usr/local/bin/*; do
        [[ -L "$link" && ! -e "$link" ]] || continue

        target="$(readlink -- "$link")"
        if [[ "$target" == "$INSTALL_DIR"/* ]]; then
            broken+=("${link##*/}")
        fi
    done

    if (( ${#broken[@]} == 0 )); then
        __report OK "No broken links in /usr/local/bin into INSTALL_DIR"

        return 0
    fi

    __report WARN "Broken links in /usr/local/bin: ${broken[*]}" \
        "Run mp remove -f for the owning module, or delete the links"
}

##
# __desktop_exec_path <desktop_file>
#
# Prints the program path of a desktop entry's first Exec line, without quotes.
#
__desktop_exec_path() {
    local line
    local program

    while IFS= read -r line; do
        [[ "$line" == Exec=* ]] || continue

        line="${line#Exec=}"
        if [[ "$line" == \"* ]]; then
            program="${line#\"}"
            program="${program%%\"*}"
        else
            program="${line%% *}"
        fi

        printf '%s\n' "$program"

        return 0
    done <"$1"
}

__check_desktop_entries() {
    local entry
    local program
    local -a broken=()

    for entry in "$__DESKTOP_DIR"/*.desktop; do
        [[ -f "$entry" ]] || continue

        program="$(__desktop_exec_path "$entry" 2>/dev/null)" || continue
        if [[ "$program" == "$INSTALL_DIR"/* && ! -e "$program" ]]; then
            broken+=("${entry##*/}")
        fi
    done

    if (( ${#broken[@]} == 0 )); then
        __report OK "No desktop entries with a missing program in INSTALL_DIR"

        return 0
    fi

    __report WARN "Desktop entries with a missing program: ${broken[*]}" \
        "Run mp remove -f for the owning module, or delete the entries"
}

__check_leftovers() {
    __print_section "Leftovers"

    __check_state_files
    __check_broken_symlinks
    __check_desktop_entries
}

main() {
    local -A options=()
    local -a args=()
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" doctor >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" doctor

        return 0
    fi

    __validate_options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" doctor >&2

        return "$status"
    fi

    printf 'Mint Provisioner Doctor\n'
    printf '%s\n' '======================='

    __check_environment
    __check_tools
    __check_distro
    __check_apt
    __check_github "${options[OFFLINE]}"
    __check_registry
    __check_leftovers

    printf '\nSummary: %b%d OK%b, %b%d WARN%b, %b%d FAIL%b\n' \
        "$COLOR_GREEN" "${__DOCTOR_COUNTS[OK]}" "$COLOR_RESET" \
        "$COLOR_YELLOW" "${__DOCTOR_COUNTS[WARN]}" "$COLOR_RESET" \
        "$COLOR_RED" "${__DOCTOR_COUNTS[FAIL]}" "$COLOR_RESET"

    if (( __DOCTOR_COUNTS[FAIL] > 0 )); then
        return 1
    fi
}

main "$@"
