#!/usr/bin/env bash
set -euo pipefail

# Hidden command used by the shell completion scripts in completion/.
# Usage: mp __complete <word>... <current_word>
# The words are the command line after "mp"; the last one is the word being
# completed and may be empty. Candidates are printed one per line; the shell
# filters them by the current prefix.

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/resolver.sh"

readonly -a __COMMANDS=(help list install plan outdated update remove uninstall purge)
readonly -a __INSTALL_OPTIONS=(-f --force -ni --non-interactive --unattended)
readonly -a __PLAN_OPTIONS=(-f --force -ni --non-interactive --unattended -h --help)
readonly -a __REMOVE_OPTIONS=(-f --force -h --help)
readonly -a __OUTDATED_OPTIONS=(-h --help)
readonly -a __LIST_TARGETS=(category modules)
readonly -a __LIST_OPTIONS=(-c --category -s --status)
readonly -a __LIST_STATUSES=(all installed not-installed)

__print_words() {
    if (( $# > 0 )); then
        printf '%s\n' "$@"
    fi
}

__print_categories() {
    local -a categories=()

    list_categories categories
    __print_words "${categories[@]}"
}

##
# __print_modules <word...>
#
# Prints module selectors that are not already among the given words.
#
__print_modules() {
    local -a selectors=()
    local -A typed=()
    local word
    local selector

    for word in "$@"; do
        typed["$word"]=1
    done

    list_module_selectors selectors || return $?

    for selector in "${selectors[@]}"; do
        if [[ ! -v "typed[$selector]" ]]; then
            printf '%s\n' "$selector"
        fi
    done
}

##
# __complete_list <previous_word> <word...>
#
# Completes 'mp list': the target, then options and their values for modules.
#
__complete_list() {
    local previous="$1"
    shift

    case "$previous" in
        list)
            __print_words "${__LIST_TARGETS[@]}"

            return 0
            ;;
        -c | --category)
            __print_categories

            return 0
            ;;
        -s | --status)
            __print_words "${__LIST_STATUSES[@]}"

            return 0
            ;;
    esac

    # Options apply only to 'mp list modules'.
    if [[ "${1:-}" == "modules" ]]; then
        __print_words "${__LIST_OPTIONS[@]}"
    fi
}

##
# __complete_modules <options_name> <current_word> <word...>
#
# Completes commands that take modules: options when the current word starts
# with '-', module selectors otherwise.
#
__complete_modules() {
    local -n module_options_ref="$1"
    local current="$2"
    shift 2

    if [[ "$current" == -* ]]; then
        __print_words "${module_options_ref[@]}"

        return 0
    fi

    __print_modules "$@"
}

main() {
    local -a words=("$@")
    local count="${#words[@]}"
    local current
    local previous
    local command

    if (( count == 0 )); then
        return 0
    fi

    current="${words[count - 1]}"

    if (( count == 1 )); then
        __print_words "${__COMMANDS[@]}"

        return 0
    fi

    command="${words[0]}"
    previous="${words[count - 2]}"

    # Words typed between the command and the current word.
    words=("${words[@]:1:count - 2}")

    case "$command" in
        help)
            if (( count == 2 )); then
                __print_words "${__COMMANDS[@]}"
            fi
            ;;
        list)
            __complete_list "$previous" "${words[@]}"
            ;;
        install)
            __complete_modules __INSTALL_OPTIONS "$current" "${words[@]}"
            ;;
        plan)
            __complete_modules __PLAN_OPTIONS "$current" "${words[@]}"
            ;;
        outdated | update)
            __complete_modules __OUTDATED_OPTIONS "$current" "${words[@]}"
            ;;
        remove | uninstall | purge)
            __complete_modules __REMOVE_OPTIONS "$current" "${words[@]}"
            ;;
    esac

    return 0
}

main "$@"
