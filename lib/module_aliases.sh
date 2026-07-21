#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if (( ${__MODULE_ALIASES_LIB_LOADED:-0} )); then
    return 0
fi

readonly __MODULE_ALIASES_LIB_LOADED=1

declare -Ar MODULE_ALIASES=(
    [anydesk]="misc/any-desk"
    [btm]="tui/bottom"
    [brave]="gui/brave-browser"
    [compass]="dev/mongodb-compass"
    [db-cmd]="gui/double-commander"
    [dbgate]="dev/dbgate-community"
    [dbeaver]="dev/dbeaver-community"
    [dnscrypt]="sys/dnscrypt-proxy"
    [dua]="tui/du-analyzer"
    [dust]="tui/du-rust"
    [edge]="gui/microsoft-edge"
    [keepass]="gui/keepass-xc"
    [keepassxc]="gui/keepass-xc"
    [maven]="dev/apache-maven"
    [mkvmerge]="cli/mkvtoolnix"
    [mu-cmd]="gui/mu-commander"
    [mvn]="dev/apache-maven"
    [omp]="term/oh-my-posh"
    [origin]="gui/brave-origin"
    [pgadmin]="dev/pg-admin"
    [plvl10k]="term/power-level-10k"
    [vbox]="misc/virtual-box"
)

##
# Returns success when a selector is a registered module alias.
#
# Parameters:
#   selector    Module selector to inspect.
#
# Returns:
#   0 when the selector is registered; 1 otherwise.
#
is_module_alias() {
    local selector="${1:-}"

    [[ -n "$selector" ]] || return 1
    [[ -n "${MODULE_ALIASES[$selector]:-}" ]]
}

##
# Resolves a registered alias into a caller-provided result variable.
#
# Parameters:
#   selector       Registered module alias.
#   result_name    Name of the destination variable.
#
# Returns:
#   0 when the alias is resolved; 1 when the selector is not an alias;
#   2 when arguments are invalid.
#
resolve_module_alias() {
    local selector="${1:-}"
    local result_name="${2:-}"

    if (( $# != 2 )) || [[ -z "$selector" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 2
    fi

    if ! is_module_alias "$selector"; then
        return 1
    fi

    declare -n result_ref="$result_name"
    result_ref="${MODULE_ALIASES[$selector]}"

    return 0
}

##
# Collects every registered alias for a canonical module ID.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#   result_name     Name of the destination array.
#
# Returns:
#   0 with all matching aliases, including when no aliases exist; 2 when
#   arguments are invalid.
#
get_module_aliases() {
    local canonical_id="${1:-}"
    local result_name="${2:-}"

    if (( $# != 2 )) || [[ -z "$canonical_id" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 2
    fi

    declare -n result_ref="$result_name"
    result_ref=()

    local module_alias
    for module_alias in "${!MODULE_ALIASES[@]}"; do
        if [[ "${MODULE_ALIASES[$module_alias]}" == "$canonical_id" ]]; then
            result_ref+=("$module_alias")
        fi
    done

    return 0
}
