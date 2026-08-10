#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"

declare -Ar __MINT_PROVISIONER_MODULE_ALIASES=(
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
    [syskit]="sys/system-toolkit"
    [vbox]="misc/virtual-box"
)

__MODULES_PRELOADED=0
declare -a __ALL_MODULES=()
declare -A __CANONICAL_MODULES=()
declare -A __UNIQUE_MODULES=()
declare -A __DUPLICATE_MODULES=()

__REVERSE_LOOKUP_PRELOADED=0
declare -A __MINT_PROVISIONER_MODULE_REVERSE_ALIASES=()

__valid_catalog_id() {
    [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

##
# list_categories
#
# Lists supported first-level category directory IDs from MP_MODULES.
#
# Parameters:
#   categories_name - Name of the indexed array that receives category IDs.
#
list_categories() {
    local categories_name="$1"
    local -n categories_ref="$categories_name"
    local category_dir
    local category_id
    local LC_ALL=C

    categories_ref=()

    for category_dir in "$MP_MODULES"/*; do
        if [[ ! -d "$category_dir" ]] || [[ -L "$category_dir" ]]; then
            continue
        fi

        category_id="${category_dir##*/}"
        if ! __valid_catalog_id "$category_id"; then
            tlog_warn "resolver" "Skipping invalid category ID: %s" "$category_id"

            continue
        fi

        categories_ref+=("$category_id")
    done

    return 0
}

##
# list_modules
#
# Lists supported second-level module directories as canonical IDs.
#
# Parameters:
#   modules_name - Name of the indexed array that receives canonical module IDs.
#   categories   - Optional category IDs to include. All categories are used
#                  when none are provided.
#
# Returns:
#   1 when one or more requested categories are unavailable.
#
list_modules() {
    local modules_name="$1"
    shift

    local -n modules_ref="$modules_name"
    local -a available_categories=()
    local -A category_flags=()
    local -a selected_categories=()
    local category
    local invalid=0
    local category_dir
    local module_dir
    local module_id
    local canonical_id
    local LC_ALL=C

    modules_ref=()

    list_categories available_categories

    if (( $# == 0 )); then
        selected_categories=("${available_categories[@]}")
    else
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
            tlog_error "resolver" "Unsupported category: %s" "$category"
        done

        if (( invalid )); then
            return 1
        fi

        # Preserve the canonical category order.
        for category in "${available_categories[@]}"; do
            if (( category_flags["$category"] )); then
                selected_categories+=("$category")
            fi
        done
    fi

    for category in "${selected_categories[@]}"; do
        category_dir="$MP_MODULES/$category"

        for module_dir in "$category_dir"/*; do
            if [[ ! -d "$module_dir" ]] || [[ -L "$module_dir" ]]; then
                continue
            fi

            module_id="${module_dir##*/}"

            if ! __valid_catalog_id "$module_id"; then
                tlog_warn "resolver:$category/$module_id" \
                    "Skipping invalid module ID"

                continue
            fi

            canonical_id="$category/$module_id"
            modules_ref+=("$canonical_id")
        done
    done

    return 0
}

__preload_all_modules() {
    if (( __MODULES_PRELOADED )); then
        return 0
    fi

    local canonical_id
    local module_id

    __ALL_MODULES=()
    __CANONICAL_MODULES=()
    __UNIQUE_MODULES=()
    __DUPLICATE_MODULES=()

    list_modules __ALL_MODULES || return $?

    for canonical_id in "${__ALL_MODULES[@]}"; do
        module_id="${canonical_id##*/}"
        __CANONICAL_MODULES["$canonical_id"]=1

        if [[ -v "__DUPLICATE_MODULES[$module_id]" ]]; then
            __DUPLICATE_MODULES["$module_id"]+=", $canonical_id"

            continue
        fi

        if [[ -v "__UNIQUE_MODULES[$module_id]" ]]; then
            __DUPLICATE_MODULES["$module_id"]="${__UNIQUE_MODULES[$module_id]}, $canonical_id"
            unset "__UNIQUE_MODULES[$module_id]"

            continue
        fi

        __UNIQUE_MODULES["$module_id"]="$canonical_id"
    done

    __MODULES_PRELOADED=1

    return 0
}

__resolve_module_selector() {
    local selector="$1"
    local result_name="$2"
    local -n result_ref="$result_name"
    local alias_target

    result_ref=""

    if [[ ! "$selector" =~ ^[a-z0-9][a-z0-9-]*(/[a-z0-9][a-z0-9-]*)?$ ]]; then
        tlog_error "resolver" "Invalid module selector: %s" "${selector:-<empty>}"

        return 1
    fi

    # Canonical IDs take priority over short IDs and aliases.
    if [[ -v "__CANONICAL_MODULES[$selector]" ]]; then
        result_ref="$selector"

        return 0
    fi

    if [[ -v "__UNIQUE_MODULES[$selector]" ]]; then
        result_ref="${__UNIQUE_MODULES[$selector]}"
        tlog_info "resolver" "Module selector resolved: %s -> %s" \
            "$selector" "${__UNIQUE_MODULES[$selector]}"

        return 0
    fi

    if [[ -v "__DUPLICATE_MODULES[$selector]" ]]; then
        tlog_error "resolver" "Ambiguous module selector '%s'. Candidates: %s" \
            "$selector" "${__DUPLICATE_MODULES[$selector]}"

        return 1
    fi

    if [[ ! -v "__MINT_PROVISIONER_MODULE_ALIASES[$selector]" ]]; then
        tlog_error "resolver" "Module not found: %s" "$selector"

        return 1
    fi

    alias_target="${__MINT_PROVISIONER_MODULE_ALIASES[$selector]}"
    if [[ -v "__CANONICAL_MODULES[$alias_target]" ]]; then
        result_ref="$alias_target"
        tlog_info "resolver" "Module alias resolved: %s -> %s" \
            "$selector" "$alias_target"

        return 0
    fi

    tlog_error "resolver" \
        "Module alias %s points to an unavailable module: %s" "$selector" "$alias_target"

    return 1
}

##
# resolve_module_selectors
#
# Resolves canonical IDs, unique short IDs, and registered aliases.
#
# Parameters:
#   modules_name - Name of the indexed array that receives canonical IDs.
#   selectors    - Module selectors to resolve.
#
# Returns:
#   1 when one or more selectors cannot be resolved.
#
resolve_module_selectors() {
    local modules_name="$1"
    shift

    local -n modules_ref="$modules_name"
    local -A seen=()
    local selector
    local canonical_id
    local failed=0

    modules_ref=()
    __preload_all_modules || return $?

    for selector in "$@"; do
        if ! __resolve_module_selector "$selector" canonical_id; then
            failed=1
            continue
        fi

        if (( ${seen["$canonical_id"]:-0} )); then
            continue
        fi

        seen["$canonical_id"]=1
        modules_ref+=("$canonical_id")
    done

    if (( failed )); then
        modules_ref=()
        return 1
    fi

    return 0
}

__preload_alias_reverse_lookup() {
    if (( __REVERSE_LOOKUP_PRELOADED )); then
        return 0
    fi

    local alias
    local canonical_id

    __MINT_PROVISIONER_MODULE_REVERSE_ALIASES=()
    for alias in "${!__MINT_PROVISIONER_MODULE_ALIASES[@]}"; do
        canonical_id="${__MINT_PROVISIONER_MODULE_ALIASES[$alias]}"

        if [[ -v "__MINT_PROVISIONER_MODULE_REVERSE_ALIASES[$canonical_id]" ]]; then
            __MINT_PROVISIONER_MODULE_REVERSE_ALIASES["$canonical_id"]+=" $alias"
        else
            __MINT_PROVISIONER_MODULE_REVERSE_ALIASES["$canonical_id"]="$alias"
        fi
    done

    __REVERSE_LOOKUP_PRELOADED=1
}

valid_canonical_id() {
    [[ "$1" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
}

##
# resolve_module_aliases
#
# Resolve current canonical id into their alisases
#
# Prarameters:
#   canonical_id - module canonical ID
#   aliases_name - Name of indexed array that receives alias(es)
#
# Return:
#   0 - when canonical ID valid
#   1 - when canonical ID not exists
#
resolve_module_aliases() {
    local canonical_id="$1"
    local aliases_name="$2"
    local -n aliases_ref="$aliases_name"
    local alias

    aliases_ref=()
    if ! valid_canonical_id "$canonical_id"; then
        tlog_error "aliases" "Invalid canonical ID: %s" "$canonical_id"

        return 1
    fi

    __preload_alias_reverse_lookup || return $?
    if [[ ! -v "__MINT_PROVISIONER_MODULE_REVERSE_ALIASES[$canonical_id]" ]]; then
        return 0
    fi

    for alias in ${__MINT_PROVISIONER_MODULE_REVERSE_ALIASES[$canonical_id]}; do
        aliases_ref+=("$alias")
    done

    return 0
}
