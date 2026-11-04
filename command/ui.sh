#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"
# Sourced directly only for its theme (__prompt_whiptail_colors); this script loads it once.
source "$LIB_INSTALLER/__prompt_whiptail.sh"

readonly __UI_TITLE="Mint Provisioner"
readonly __UI_MIN_LINES=24
readonly __UI_MIN_COLUMNS=80
readonly __UI_MAX_WIDTH=100
readonly -a __UI_COMMANDS=(info install plan outdated upgrade remove purge)
readonly -A __UI_COMMAND_LABELS=(
    [info]="Show module details"
    [install]="Install modules"
    [plan]="Preview an installation"
    [outdated]="Check installed modules for updates"
    [upgrade]="Upgrade installed modules"
    [remove]="Remove installed modules"
    [purge]="Remove installed modules and their data"
)

# Module catalog and installed state, filled once by __detect_modules.
declare -a __UI_MODULES=()
declare -A __UI_NAMES=()
declare -A __UI_DESCRIPTIONS=()
declare -A __UI_STATUSES=()
declare -a __UI_CATEGORIES=()
declare -A __UI_CATEGORY_NAMES=()
__UI_DETECTED=0
# Modules picked in the module menu of the current command (canonical ID -> 1).
declare -A __UI_SELECTED=()
# Dialog geometry, set by __load_terminal_size.
__UI_HEIGHT=0
__UI_WIDTH=0
__UI_LIST_HEIGHT=0

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
            -*)
                log_error "Unsupported ui option: %s" "$1"

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
        log_error "The ui command does not accept arguments: %s" "${args_ref[*]}"

        return 2
    fi
}

##
# __terminal_usable
#
# Checks that whiptail is installed and the controlling terminal can be used.
#
# Return:
#   1 when whiptail or the terminal is unavailable.
#
__terminal_usable() {
    command -v whiptail >/dev/null 2>&1 &&
        [[ -r /dev/tty && -w /dev/tty ]] &&
        { : </dev/tty; } 2>/dev/null &&
        { : >/dev/tty; } 2>/dev/null
}

##
# __load_terminal_size
#
# Sizes the dialogs from the terminal size.
#
# Return:
#   1 when the terminal is smaller than the supported minimum.
#
__load_terminal_size() {
    local lines
    local columns

    read -r lines columns < <(stty size </dev/tty)

    if (( lines < __UI_MIN_LINES || columns < __UI_MIN_COLUMNS )); then
        log_error "mp ui needs a terminal of at least %dx%d (current: %dx%d)" \
            "$__UI_MIN_COLUMNS" "$__UI_MIN_LINES" "$columns" "$lines"

        return 1
    fi

    __UI_HEIGHT=$(( lines - 4 ))
    __UI_WIDTH=$(( columns - 4 < __UI_MAX_WIDTH ? columns - 4 : __UI_MAX_WIDTH ))
    __UI_LIST_HEIGHT=$(( __UI_HEIGHT - 8 ))
}

##
# __ui_whiptail <whiptail_arg>...
#
# Runs a themed whiptail dialog on the controlling terminal.
#
# Output:
#   Prints the dialog result.
#
# Return:
#   whiptail's status: 1 for Cancel or No, 255 for Esc.
#
__ui_whiptail() {
    env -u NEWT_COLORS_FILE NEWT_COLORS="$__prompt_whiptail_colors" \
        whiptail --title "$__UI_TITLE" "$@" 3>&1 1>&2 2>&3 </dev/tty >/dev/tty
}

__ui_message() {
    __ui_whiptail --msgbox "$1" 10 60 || true
}

##
# __ui_gauge <text>
#
# Shows a themed progress gauge that reads percentages from standard input
# until it is closed. An --infobox would exit at once, and terminals with an
# alternate screen clear it immediately.
#
__ui_gauge() {
    env -u NEWT_COLORS_FILE NEWT_COLORS="$__prompt_whiptail_colors" \
        whiptail --title "$__UI_TITLE" --gauge "$1" 7 60 0 >/dev/tty 2>&1
}

__detect_modules() {
    local -A module_metadata=()
    local canonical_id
    local status
    local gauge_fd
    local gauge_pid
    local done_count=0
    local -A category_metadata=()
    local category

    list_categories __UI_CATEGORIES
    for category in "${__UI_CATEGORIES[@]}"; do
        __UI_CATEGORY_NAMES["$category"]="$category"
        if parse_category_metadata "$MP_MODULES/$category" category_metadata 2>/dev/null; then
            __UI_CATEGORY_NAMES["$category"]="${category_metadata[NAME]}"
        fi
    done

    list_modules __UI_MODULES || return $?

    exec {gauge_fd}> >(__ui_gauge "Detecting installed modules...")
    gauge_pid=$!

    for canonical_id in "${__UI_MODULES[@]}"; do
        printf '%d\n' $(( done_count * 100 / ${#__UI_MODULES[@]} )) >&"$gauge_fd" 2>/dev/null || true
        (( done_count += 1 ))
        status=0
        if parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata 2>/dev/null; then
            __UI_NAMES["$canonical_id"]="${module_metadata[NAME]}"
            __UI_DESCRIPTIONS["$canonical_id"]="${module_metadata[DESCRIPTION]}"
            module_installed "$canonical_id" module_metadata >/dev/null 2>&1 || status=$?
        else
            __UI_NAMES["$canonical_id"]="$canonical_id"
            status=2
        fi

        __UI_STATUSES["$canonical_id"]="$status"
    done

    exec {gauge_fd}>&-
    wait "$gauge_pid" || true

    __UI_DETECTED=1
}

##
# __choose_command <command_name>
#
# Shows the welcome menu and stores the selected command.
#
# Return:
#   1 when the menu was cancelled.
#
__choose_command() {
    local -n command_ref="$1"
    local -a menu_items=()
    local menu_command

    for menu_command in "${__UI_COMMANDS[@]}"; do
        menu_items+=("$menu_command" "${__UI_COMMAND_LABELS[$menu_command]}")
    done

    command_ref="$(__ui_whiptail --cancel-button "Quit" --menu \
        "Welcome to Mint Provisioner.\n\nChoose what to do:" \
        "$__UI_HEIGHT" "$__UI_WIDTH" "${#__UI_COMMANDS[@]}" "${menu_items[@]}")" || return 1
}

__installed_only() {
    case "$1" in
        outdated | upgrade | remove | purge)
            return 0
            ;;
    esac

    return 1
}

__allows_empty_selection() {
    case "$1" in
        outdated | upgrade)
            return 0
            ;;
    esac

    return 1
}

##
# __module_offered <command> <canonical_id>
#
# Checks whether a module is offered for a command. Installed-only commands
# skip modules detected as not installed; failed detection is still offered.
#
# Return:
#   1 when the module is not offered.
#
__module_offered() {
    local command="$1"
    local canonical_id="$2"

    if __installed_only "$command" && (( ${__UI_STATUSES[$canonical_id]} == 1 )); then
        return 1
    fi
}

__module_label() {
    local canonical_id="$1"
    local label="${__UI_NAMES[$canonical_id]}"

    case "${__UI_STATUSES[$canonical_id]}" in
        0)
            label+=" [installed]"
            ;;
        1)
            ;;
        *)
            label+=" [unknown]"
            ;;
    esac

    printf '%s\n' "$label"
}

##
# __pick_modules <prompt> <canonical_id>...
#
# Shows a checklist of the given modules, checked when already selected, and
# updates __UI_SELECTED for them. Cancel leaves the selection unchanged.
#
__pick_modules() {
    local prompt="$1"
    shift

    local -a checklist_items=()
    local -A checked=()
    local canonical_id
    local state
    local output

    for canonical_id in "$@"; do
        state="OFF"
        if [[ -v "__UI_SELECTED[$canonical_id]" ]]; then
            state="ON"
        fi

        checklist_items+=("$canonical_id" "$(__module_label "$canonical_id")" "$state")
    done

    output="$(__ui_whiptail --separate-output --checklist "$prompt\nSpace toggles a module, Enter confirms." \
        "$__UI_HEIGHT" "$__UI_WIDTH" "$__UI_LIST_HEIGHT" "${checklist_items[@]}")" || return 0

    while IFS= read -r canonical_id; do
        [[ -n "$canonical_id" ]] || continue

        checked["$canonical_id"]=1
    done <<<"$output"

    # Only the shown modules change, so unchecking one removes it from the selection.
    for canonical_id in "$@"; do
        if [[ -v "checked[$canonical_id]" ]]; then
            __UI_SELECTED["$canonical_id"]=1
        else
            unset "__UI_SELECTED[$canonical_id]"
        fi
    done
}

##
# __module_matches <query> <canonical_id>
#
# Checks whether every word of the query appears, case-insensitively, in the
# module's canonical ID, name, description, or aliases.
#
# Return:
#   1 when a word does not match.
#
__module_matches() {
    local query="${1,,}"
    local canonical_id="$2"
    local -a aliases=()
    local -a words=()
    local haystack
    local word

    resolve_module_aliases "$canonical_id" aliases 2>/dev/null || true
    haystack="$canonical_id ${__UI_NAMES[$canonical_id]} ${__UI_DESCRIPTIONS[$canonical_id]:-} ${aliases[*]}"
    haystack="${haystack,,}"

    read -ra words <<<"$query"
    for word in "${words[@]}"; do
        [[ "$haystack" == *"$word"* ]] || return 1
    done
}

__search_modules() {
    local command="$1"
    local -a matches=()
    local canonical_id
    local query

    query="$(__ui_whiptail --inputbox \
        "Search modules (words match ID, name, alias, or description):" \
        10 "$__UI_WIDTH")" || return 0

    if [[ -z "${query//[[:space:]]/}" ]]; then
        return 0
    fi

    for canonical_id in "${__UI_MODULES[@]}"; do
        __module_offered "$command" "$canonical_id" || continue

        if __module_matches "$query" "$canonical_id"; then
            matches+=("$canonical_id")
        fi
    done

    if (( ${#matches[@]} == 0 )); then
        __ui_message "No modules match '$query'."

        return 0
    fi

    __pick_modules "Results for '$query' (${#matches[@]}):" "${matches[@]}"
}

##
# __choose_modules <command> <modules_name>
#
# Shows the module menu (search, all modules, categories, done) for a command
# and stores the selected canonical IDs in catalog order. Selections are kept
# across the menu entries until Done.
#
# Return:
#   1 when the menu was cancelled.
#   3 when the command has no module to offer.
#
__choose_modules() {
    local command="$1"
    local -n modules_ref="$2"
    local -a offered=()
    local -a category_ids=()
    local -a menu_items=()
    local -A category_offered=()
    local -A category_selected=()
    local canonical_id
    local category
    local count_label="modules"
    local done_label
    local label
    local choice="Search..."
    local selected_count

    __UI_SELECTED=()

    for canonical_id in "${__UI_MODULES[@]}"; do
        if __module_offered "$command" "$canonical_id"; then
            offered+=("$canonical_id")
            category="${canonical_id%%/*}"
            category_offered["$category"]=$(( ${category_offered[$category]:-0} + 1 ))
        fi
    done

    if (( ${#offered[@]} == 0 )); then
        __ui_message "No installed modules to $command."

        return 3
    fi

    if __installed_only "$command"; then
        count_label="installed"
    fi

    while true; do
        category_selected=()
        selected_count=0
        for canonical_id in "${!__UI_SELECTED[@]}"; do
            category="${canonical_id%%/*}"
            category_selected["$category"]=$(( ${category_selected[$category]:-0} + 1 ))
            (( selected_count += 1 ))
        done

        menu_items=(
            "Search..." "Find modules by name, ID, alias, or description"
            "All" "All modules (${#offered[@]} $count_label)"
        )

        for category in "${__UI_CATEGORIES[@]}"; do
            [[ -v "category_offered[$category]" ]] || continue

            label="${__UI_CATEGORY_NAMES[$category]} (${category_offered[$category]} $count_label"
            if [[ -v "category_selected[$category]" ]]; then
                label+=", ${category_selected[$category]} selected"
            fi

            menu_items+=("$category" "$label)")
        done

        if (( selected_count > 0 )); then
            done_label="Continue with $selected_count selected module(s)"
        elif __allows_empty_selection "$command"; then
            done_label="Continue with every installed module"
        else
            done_label="Select at least one module first"
        fi

        menu_items+=("Done" "$done_label")

        choice="$(__ui_whiptail --default-item "$choice" --cancel-button "Back" --menu \
            "Pick modules to $command by category or search. Selections are kept until Done." \
            "$__UI_HEIGHT" "$__UI_WIDTH" "$__UI_LIST_HEIGHT" "${menu_items[@]}")" || return 1

        case "$choice" in
            "Search...")
                __search_modules "$command"
                ;;
            All)
                __pick_modules "All modules to $command:" "${offered[@]}"
                ;;
            Done)
                if (( selected_count == 0 )) && ! __allows_empty_selection "$command"; then
                    __ui_message "Select at least one module."

                    continue
                fi

                modules_ref=()
                for canonical_id in "${__UI_MODULES[@]}"; do
                    if [[ -v "__UI_SELECTED[$canonical_id]" ]]; then
                        modules_ref+=("$canonical_id")
                    fi
                done

                return 0
                ;;
            *)
                category_ids=()
                for canonical_id in "${offered[@]}"; do
                    if [[ "${canonical_id%%/*}" == "$choice" ]]; then
                        category_ids+=("$canonical_id")
                    fi
                done

                __pick_modules "${__UI_CATEGORY_NAMES[$choice]}: modules to $command:" "${category_ids[@]}"
                ;;
        esac
    done
}

##
# __choose_options <command> <options_name>
#
# Shows the option checklist of a command, if it has options, and stores the
# selected command-line options.
#
# Return:
#   1 when the checklist was cancelled.
#
__choose_options() {
    local command="$1"
    local -n chosen_ref="$2"
    local -a checklist_items=()
    local -a selected=()
    local option
    local output

    chosen_ref=()

    # Tags have no leading dashes so whiptail does not read them as options.
    case "$command" in
        info)
            checklist_items=(latest "Also resolve installed and latest versions" OFF)
            ;;
        install | plan)
            checklist_items=(
                force "Process modules already detected as installed" OFF
                non-interactive "Skip prompts; use detected values or defaults" OFF
            )
            ;;
        remove)
            checklist_items=(force "Process modules not detected as installed" OFF)
            ;;
        upgrade)
            checklist_items=(yes "Skip the confirmation (sudo must be cached)" OFF)
            ;;
        *)
            return 0
            ;;
    esac

    output="$(__ui_whiptail --separate-output --checklist "Options for mp $command:" \
        15 "$__UI_WIDTH" $(( ${#checklist_items[@]} / 3 )) "${checklist_items[@]}")" || return 1

    if [[ -z "$output" ]]; then
        return 0
    fi

    mapfile -t selected <<<"$output"
    for option in "${selected[@]}"; do
        chosen_ref+=("--$option")
    done
}

##
# __confirm <word>...
#
# Asks whether to run the mp command line made of the given words.
#
# Return:
#   1 when the user declined or cancelled.
#
__confirm() {
    __ui_whiptail --yes-button "Run" --no-button "Back" --yesno \
        "Run this command?\n\n  mp $*" 12 "$__UI_WIDTH"
}

main() {
    local -A options=()
    local -a args=()
    local -a modules=()
    local -a command_options=()
    local command=""
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" ui >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" ui

        return 0
    fi

    __validate_options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" ui >&2

        return "$status"
    fi

    if ! __terminal_usable; then
        log_error "mp ui needs whiptail and an interactive terminal (sudo apt install whiptail)"

        return 2
    fi

    __load_terminal_size || return 2

    while true; do
        __choose_command command || return 0

        if (( ! __UI_DETECTED )); then
            __detect_modules || return 1
        fi

        __choose_modules "$command" modules || continue
        __choose_options "$command" command_options || continue
        __confirm "$command" "${command_options[@]}" "${modules[@]}" || continue

        clear >/dev/tty 2>/dev/null || true
        exec bash "$MP_COMMAND/main.sh" "$command" "${command_options[@]}" "${modules[@]}"
    done
}

main "$@"
